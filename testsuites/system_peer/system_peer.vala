using Netsukuku.Coordinator;
using Netsukuku.PeerServices;

using Gee;
using Netsukuku;
using TaskletSystem;

namespace SystemPeer
{
    string json_string_object(Object obj)
    {
        Json.Node n = Json.gobject_serialize(obj);
        Json.Generator g = new Json.Generator();
        g.root = n;
        string ret = g.to_data(null);
        return ret;
    }

    string topology;
    string firstaddr;
    int pid;
    [CCode (array_length = false, array_null_terminated = true)]
    string[] interfaces;
    [CCode (array_length = false, array_null_terminated = true)]
    string[] arcs;
    [CCode (array_length = false, array_null_terminated = true)]
    string[] _tasks;

    ITasklet tasklet;
    HashMap<int,IdentityData> local_identities;
    SkeletonFactory skeleton_factory;
    StubFactory stub_factory;
    HashMap<string,PseudoNetworkInterface> pseudonic_map;
    ArrayList<PseudoArc> arc_list;
    int next_local_identity_index = 0;
    ArrayList<int> gsizes;
    ArrayList<int> g_exp;
    int levels;
    ArrayList<string> tester_events;

    IdentityData create_local_identity(NodeID nodeid, int local_identity_index)
    {
        if (local_identities == null) local_identities = new HashMap<int,IdentityData>();
        assert(! (nodeid.id in local_identities.keys));
        IdentityData ret = new IdentityData(nodeid, local_identity_index);
        local_identities[nodeid.id] = ret;
        return ret;
    }

    IdentityData? find_local_identity(NodeID nodeid)
    {
        assert(local_identities != null);
        if (nodeid.id in local_identities.keys) return local_identities[nodeid.id];
        return null;
    }

    IdentityData? find_local_identity_by_index(int local_identity_index)
    {
        assert(local_identities != null);
        foreach (IdentityData id in local_identities.values)
            if (id.local_identity_index == local_identity_index)
            return id;
        return null;
    }

    void remove_local_identity(NodeID nodeid)
    {
        assert(local_identities != null);
        assert(nodeid.id in local_identities.keys);
        local_identities.unset(nodeid.id);
    }

    int main(string[] _args)
    {
        pid = 0; // default
        topology = "1,1,1,2"; // default
        firstaddr = ""; // default
        OptionContext oc = new OptionContext("<options>");
        OptionEntry[] entries = new OptionEntry[7];
        int index = 0;
        entries[index++] = {"topology", '\0', 0, OptionArg.STRING, ref topology, "Topology in bits. Default: 1,1,1,2", null};
        entries[index++] = {"firstaddr", '\0', 0, OptionArg.STRING, ref firstaddr, "First address. E.g. '0,0,1,3'. Default is random.", null};
        entries[index++] = {"pid", 'p', 0, OptionArg.INT, ref pid, "Fake PID (e.g. -p 1234).", null};
        entries[index++] = {"interfaces", 'i', 0, OptionArg.STRING_ARRAY, ref interfaces, "Interface (e.g. -i eth1). You can use it multiple times.", null};
        entries[index++] = {"arcs", 'a', 0, OptionArg.STRING_ARRAY, ref arcs, "Arc my_dev,peer_pid,peer_dev,cost (e.g. -a eth1,5678,eth0,300). You can use it multiple times.", null};
        entries[index++] = {"tasks", 't', 0, OptionArg.STRING_ARRAY, ref _tasks,
                "Task. You can use it multiple times.\n\t\t\t " +
                "E.g.: -t add_idarc,2000,1,0,1 means: after 2000 ms add an identity-arc\n\t\t\t " +
                "on arc #1 from my identity #0 to peer's identity #1.\n\t\t\t " +
                "See readme for docs on each task.", null};
        entries[index++] = { null };
        oc.add_main_entries(entries, null);
        try {
            oc.parse(ref _args);
        }
        catch (OptionError e) {
            print(@"Error parsing options: $(e.message)\n");
            return 1;
        }

        ArrayList<string> args = new ArrayList<string>.wrap(_args);
        tester_events = new ArrayList<string>();

        // Topoplogy of the network.
        gsizes = new ArrayList<int>();
        g_exp = new ArrayList<int>();
        string[] topology_bits_array = topology.split(",");
        foreach (string s_topology_bits in topology_bits_array)
        {
            int64 topology_bits;
            if (! int64.try_parse(s_topology_bits, out topology_bits)) error("Bad arg topology");
            int _g_exp = (int)topology_bits;

            if (_g_exp < 1 || _g_exp > 16) error(@"Bad g_exp $(_g_exp): must be between 1 and 16");
            int gsize = 1 << _g_exp;
            g_exp.add(_g_exp);
            gsizes.add(gsize);
        }
        levels = gsizes.size;
        ArrayList<int> naddr = new ArrayList<int>();
        // If first address is forced:
        if (firstaddr != "")
        {
            string[] firstaddr_array = firstaddr.split(",");
            if (firstaddr_array.length != levels) error("Bad first address");
            for (int i = 0; i < levels; i++)
            {
                string s_firstaddr_part = firstaddr_array[i];
                int64 i_firstaddr_part;
                if (! int64.try_parse(s_firstaddr_part, out i_firstaddr_part)) error("Bad first address");
                if (i_firstaddr_part < 0 || i_firstaddr_part > gsizes[i]-1) error("Bad first address");
                naddr.add((int)i_firstaddr_part);
            }
        }

        // Names of the network interfaces to do RPC.
        ArrayList<string> devs = new ArrayList<string>();
        foreach (string dev in interfaces) devs.add(dev);

        // Definitions of the node-arcs.
        ArrayList<string> pseudo_arc_mydev_list = new ArrayList<string>();
        ArrayList<int> pseudo_arc_peerpid_list = new ArrayList<int>();
        ArrayList<string> pseudo_arc_peerdev_list = new ArrayList<string>();
        ArrayList<long> pseudo_arc_cost_list = new ArrayList<long>();
        foreach (string arc in arcs)
        {
            string[] arc_items = arc.split(",");
            if (arc_items.length != 4) error("bad args num in '--arcs'");
            string arc_item_my_dev = arc_items[0];
            if (! (arc_item_my_dev in devs)) error("bad arg my_dev in '--arcs'");
            int64 _arc_item_peer_pid;
            if (! int64.try_parse(arc_items[1], out _arc_item_peer_pid)) error("bad arg peer_pid in '--arcs'");
            if ((int)_arc_item_peer_pid == pid) error("bad arg peer_pid in '--arcs'");
            string arc_item_peer_dev = arc_items[2];
            int64 _arc_item_cost;
            if (! int64.try_parse(arc_items[3], out _arc_item_cost)) error("bad arg cost in '--arcs'");
            pseudo_arc_mydev_list.add(arc_item_my_dev);
            pseudo_arc_peerpid_list.add((int)_arc_item_peer_pid);
            pseudo_arc_peerdev_list.add(arc_item_peer_dev);
            pseudo_arc_cost_list.add((long)_arc_item_cost);
        }

        ArrayList<string> tasks = new ArrayList<string>();
        foreach (string task in _tasks) tasks.add(task);

        if (pid == 0) error("Bad usage");
        if (devs.is_empty) error("Bad usage");

        // Initialize tasklet system
        PthTaskletImplementer.init();
        tasklet = PthTaskletImplementer.get_tasklet_system();

        // Initialize modules that have remotable methods (serializable classes need to be registered).
        PeersManager.init(tasklet);
        CoordinatorManager.init(tasklet);
        typeof(IdentityAwareSourceID).class_peek();
        typeof(IdentityAwareUnicastID).class_peek();
        typeof(IdentityAwareBroadcastID).class_peek();
        typeof(NeighbourSrcNic).class_peek();

        // Initialize pseudo-random number generators.
        string _seed = @"$(pid)";
        uint32 seed_prn = (uint32)_seed.hash();
        PRNGen.init_rngen(null, seed_prn);
        PeersManager.init_rngen(null, seed_prn);
        CoordinatorManager.init_rngen(null, seed_prn);

        // If first address is random:
        if (firstaddr == "")
            for (int i = 0; i < levels; i++)
                naddr.add((int)PRNGen.int_range(0, gsizes[i]));

        // Pass tasklet system to the RPC library (ntkdrpc)
        init_tasklet_system(tasklet);

        // RPC
        skeleton_factory = new SkeletonFactory();
        stub_factory = new StubFactory();

        pseudonic_map = new HashMap<string,PseudoNetworkInterface>();
        arc_list = new ArrayList<PseudoArc>();
        foreach (string dev in devs)
        {
            assert(!(dev in pseudonic_map.keys));
            string listen_pathname = @"recv_$(pid)_$(dev)";
            string send_pathname = @"send_$(pid)_$(dev)";
            string mac = fake_random_mac(pid, dev);
            // @"fe:aa:aa:$(PRNGen.int_range(10, 100)):$(PRNGen.int_range(10, 100)):$(PRNGen.int_range(10, 100))";
            print(@"INFO: mac for $(pid),$(dev) is $(mac).\n");
            PseudoNetworkInterface pseudonic = new PseudoNetworkInterface(dev, listen_pathname, send_pathname, mac);
            pseudonic_map[dev] = pseudonic;

            // Start listen datagram on dev
            skeleton_factory.start_datagram_system_listen(listen_pathname, send_pathname, new NeighbourSrcNic(mac));
            tasklet.ms_wait(1);
            print(@"started datagram_system_listen $(listen_pathname) $(send_pathname) $(mac).\n");

            // Start listen stream on linklocal
            string linklocal = fake_random_linklocal(mac);
            // @"169.254.$(PRNGen.int_range(1, 255)).$(PRNGen.int_range(1, 255))";
            print(@"INFO: linklocal for $(mac) is $(linklocal).\n");
            pseudonic.linklocal = linklocal;
            pseudonic.st_listen_pathname = @"conn_$(linklocal)";
            skeleton_factory.start_stream_system_listen(pseudonic.st_listen_pathname);
            tasklet.ms_wait(1);
            print(@"started stream_system_listen $(pseudonic.st_listen_pathname).\n");
        }
        for (int i = 0; i < pseudo_arc_mydev_list.size; i++)
        {
            string my_dev = pseudo_arc_mydev_list[i];
            int peer_pid = pseudo_arc_peerpid_list[i];
            string peer_dev = pseudo_arc_peerdev_list[i];
            long cost = pseudo_arc_cost_list[i];
            string peer_mac = fake_random_mac(peer_pid, peer_dev);
            string peer_linklocal = fake_random_linklocal(peer_mac);
            PseudoArc pseudoarc = new PseudoArc(my_dev, peer_pid, peer_mac, peer_linklocal, cost);
            arc_list.add(pseudoarc);
            print(@"INFO: arc #$(i) from $(my_dev) to pid$(peer_pid)+$(peer_dev)=$(peer_linklocal) with base cost of RTT = $(cost) usec\n");
        }

        // first id
        NodeID first_nodeid = fake_random_nodeid(pid, next_local_identity_index);
        string first_identity_name = @"$(pid)_$(next_local_identity_index)";
        print(@"INFO: nodeid for $(first_identity_name) is $(first_nodeid.id).\n");
        IdentityData first_identity_data = create_local_identity(first_nodeid, next_local_identity_index);
        first_identity_data.my_naddr_pos = new ArrayList<int>();
        first_identity_data.my_naddr_pos.add_all(naddr);
        next_local_identity_index++;

        //  public PeersManager (PeersManager? old_identity,
        //                      int guest_gnode_level, int host_gnode_level,
        //                      IPeersMapPaths map_paths, IPeersBackStubFactory back_stub_factory,
        //                      IPeersNeighborsFactory neighbors_factory);

        first_identity_data.peers_mgr = new PeersManager(null,0,0,
            new PeersMapPaths(first_identity_data.local_identity_index),
            new PeersBackStubFactory(first_identity_data.local_identity_index),
            new PeersNeighborsFactory(first_identity_data.local_identity_index));

        first_identity_data = null;

        foreach (string task in tasks)
        {
            if      (schedule_task_add_identity(task)) {}
            else error(@"unknown task $(task)");
        }

        // TODO

        // Temporary: register handlers for SIGINT and SIGTERM to exit
        Posix.@signal(Posix.Signal.INT, safe_exit);
        Posix.@signal(Posix.Signal.TERM, safe_exit);
        // Main loop
        while (true)
        {
            tasklet.ms_wait(100);
            if (do_me_exit) break;
        }

        // TODO

        // Call stop_rpc.
        ArrayList<string> final_devs = new ArrayList<string>();
        final_devs.add_all(pseudonic_map.keys);
        foreach (string dev in final_devs)
        {
            PseudoNetworkInterface pseudonic = pseudonic_map[dev];
            skeleton_factory.stop_stream_system_listen(pseudonic.st_listen_pathname);
            print(@"stopped stream_system_listen $(pseudonic.st_listen_pathname).\n");
            skeleton_factory.stop_datagram_system_listen(pseudonic.listen_pathname);
            print(@"stopped datagram_system_listen $(pseudonic.listen_pathname).\n");
            pseudonic_map.unset(dev);
        }
        skeleton_factory = null;

        PthTaskletImplementer.kill();

        print("Exiting. Event list:\n");
        foreach (string s in tester_events) print(@"$(s)\n");

        return 0;
    }

    bool do_me_exit = false;
    void safe_exit(int sig)
    {
        // We got here because of a signal. Quick processing.
        do_me_exit = true;
    }

    class PseudoNetworkInterface : Object
    {
        public PseudoNetworkInterface(string dev, string listen_pathname, string send_pathname, string mac)
        {
            this.dev = dev;
            this.listen_pathname = listen_pathname;
            this.send_pathname = send_pathname;
            this.mac = mac;
        }
        public string mac {get; private set;}
        public string send_pathname {get; private set;}
        public string listen_pathname {get; private set;}
        public string dev {get; private set;}
        public string linklocal {get; set;}
        public string st_listen_pathname {get; set;}
    }

    class PseudoArc : Object
    {
        public PseudoArc(string my_dev, int peer_pid, string peer_mac, string peer_linklocal, long cost)
        {
            assert(pseudonic_map.has_key(my_dev));
            my_nic = pseudonic_map[my_dev];
            this.peer_pid = peer_pid;
            this.peer_mac = peer_mac;
            this.peer_linklocal = peer_linklocal;
            this.cost = cost;
        }
        public PseudoNetworkInterface my_nic {get; private set;}
        public int peer_pid {get; private set;}
        public string peer_mac {get; private set;}
        public string peer_linklocal {get; private set;}
        public long cost {get; set;}
    }

    string fake_random_mac(int pid, string dev)
    {
        string _seed = @"$(pid)_$(dev)";
        uint32 seed_prn = (uint32)_seed.hash();
        Rand _rand = new Rand.with_seed(seed_prn);
        return @"fe:aa:aa:$(_rand.int_range(10, 100)):$(_rand.int_range(10, 100)):$(_rand.int_range(10, 100))";
    }

    string fake_random_linklocal(string mac)
    {
        uint32 seed_prn = (uint32)mac.hash();
        Rand _rand = new Rand.with_seed(seed_prn);
        return @"169.254.$(_rand.int_range(1, 255)).$(_rand.int_range(1, 255))";
    }

    NodeID fake_random_nodeid(int pid, int node_index)
    {
        string _seed = @"$(pid)_$(node_index)";
        uint32 seed_prn = (uint32)_seed.hash();
        Rand _rand = new Rand.with_seed(seed_prn);
        return new NodeID((int)(_rand.int_range(1, 100000)));
    }

    class IdentityData : Object
    {
        public IdentityData(NodeID nodeid, int local_identity_index)
        {
            this.local_identity_index = local_identity_index;
            this.nodeid = nodeid;
            identity_arcs = new ArrayList<IdentityArc>();
            connectivity_from_level = 0;
            connectivity_to_level = 0;
            copy_of_identity = null;
            gateways = new HashMap<int,HashMap<int,ArrayList<IdentityArc>>>();
            for (int i = 0; i < levels; i++) gateways[i] = new HashMap<int,ArrayList<IdentityArc>>();
        }

        public int local_identity_index;

        public NodeID nodeid;
        public int connectivity_from_level;
        public int connectivity_to_level;
        public weak IdentityData? copy_of_identity;
        public bool main_id {
            get {
                return connectivity_from_level == 0;
            }
        }

        public PeersManager peers_mgr;
        public CoordinatorManager coord_mgr;

        public ArrayList<int> my_naddr_pos;
        public HCoord my_naddr_get_coord_by_address(ArrayList<int> dest_pos)
        {
            int l = my_naddr_pos.size-1;
            while (l >= 0)
            {
                if (my_naddr_pos[l] != dest_pos[l]) return new HCoord(l, dest_pos[l]);
                l--;
            }
            // same naddr: error
            return new HCoord(-1, -1);
        }

        public HashMap<int,HashMap<int,ArrayList<IdentityArc>>> gateways;
        // gateways[3][2][0] means the best gateway to (3,2).

        public ArrayList<IdentityArc> identity_arcs;
        public IdentityArc? identity_arcs_find(PseudoArc arc, NodeID peer_nodeid)
        {
            assert(identity_arcs != null);
            foreach (IdentityArc ia in identity_arcs)
                if (ia.arc == arc && ia.peer_nodeid.equals(peer_nodeid))
                return ia;
            return null;
        }

    }

    class IdentityArc : Object
    {
        private int local_identity_index;
        private IdentityData? _identity_data;
        public IdentityData identity_data {
            get {
                _identity_data = find_local_identity_by_index(local_identity_index);
                if (_identity_data == null) tasklet.exit_tasklet();
                return _identity_data;
            }
        }
        public PseudoArc arc;
        public NodeID peer_nodeid;
        public ArrayList<int> peer_naddr_pos;

        public IdentityArc(int local_identity_index, PseudoArc arc, NodeID peer_nodeid)
        {
            this.local_identity_index = local_identity_index;
            this.arc = arc;
            this.peer_nodeid = peer_nodeid;
        }
    }

    string printabletime()
    {
        TimeVal now = TimeVal();
        now.get_current_time();
        string s_usec = @"$(now.tv_usec + 1000000)";
        s_usec = s_usec.substring(1);
        string s_sec = @"$(now.tv_sec)";
        s_sec = s_sec.substring(s_sec.length-3);
        return @"$(s_sec).$(s_usec)";
    }
}