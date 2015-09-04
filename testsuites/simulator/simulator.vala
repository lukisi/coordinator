using Netsukuku;
using Netsukuku.ModRpc;
using Gee;

string json_string_object(Object obj)
{
    Json.Node n = Json.gobject_serialize(obj);
    Json.Generator g = new Json.Generator();
    g.root = n;
    g.pretty = true;
    string ret = g.to_data(null);
    return ret;
}

void print_object(Object obj)
{
    print(@"$(obj.get_type().name())\n");
    string t = json_string_object(obj);
    print(@"$(t)\n");
}

Object dup_object(Object obj)
{
    //print(@"dup_object...\n");
    Type type = obj.get_type();
    string t = json_string_object(obj);
    Json.Parser p = new Json.Parser();
    try {
        assert(p.load_from_data(t));
    } catch (Error e) {assert_not_reached();}
    Object ret = Json.gobject_deserialize(type, p.get_root());
    //print(@"dup_object done.\n");
    return ret;
}

public class SimulatorNode : Object
{
    public MyPeersMapPath map_paths;
    public MyPeersBackStubFactory back_factory;
    public MyPeersNeighborsFactory neighbor_factory;
    public MyCoordinatorMap map;
    public PeersManager peers_manager;
    public CoordinatorManager coordinator_manager;
}

INtkdTasklet tasklet;
void main()
{
    // init tasklet
    MyTaskletSystem.init();
    tasklet = MyTaskletSystem.get_ntkd();

    // pass tasklet system to modules
    PeersManager.init(tasklet);
    CoordinatorManager.init(tasklet);

    print("ok\n");
    var n0 = new SimulatorNode();
    n0.map_paths = new MyPeersMapPath({4, 4, 4, 4}, {1, 0, 3, 3});
    n0.back_factory = new MyPeersBackStubFactory();
    n0.neighbor_factory = new MyPeersNeighborsFactory();
    n0.map = new MyCoordinatorMap({4, 4, 4, 4}, {0, 0, 0, 0});
    n0.map.free_pos[0] = new ArrayList<int>.wrap({0, 2});
    n0.map.free_pos[1] = new ArrayList<int>.wrap({1, 2, 3});
    n0.map.free_pos[2] = new ArrayList<int>.wrap({1, 2});
    n0.map.free_pos[3] = new ArrayList<int>.wrap({0, 1, 2});
    n0.peers_manager = new PeersManager(n0.map_paths,
                             4,  /*first node in whole network of 4 levels*/
                             n0.back_factory,
                             n0.neighbor_factory);
    n0.coordinator_manager = new CoordinatorManager(n0.peers_manager, n0.map);
    n0.coordinator_manager.bootstrap_complete(4);
    n0.coordinator_manager.presence_notified();

    var n1 = new SimulatorNode();
    n1.map_paths = new MyPeersMapPath({4, 4, 16}, {2, 3, 12});
    n1.back_factory = new MyPeersBackStubFactory();
    n1.neighbor_factory = new MyPeersNeighborsFactory();
    n1.map = new MyCoordinatorMap({4, 4, 16}, {0, 0, 0});
    // no space left, free_pos are empty.
    n1.peers_manager = new PeersManager(n1.map_paths,
                             3,  /*first node in whole network of 3 levels*/
                             n1.back_factory,
                             n1.neighbor_factory);
    n1.coordinator_manager = new CoordinatorManager(n1.peers_manager, n1.map);
    n1.coordinator_manager.bootstrap_complete(3);
    n1.coordinator_manager.presence_notified();

    try {
        var stub0 = new MyCoordinatorManagerStub(n0.coordinator_manager);
        ICoordinatorNeighborMap resp = n1.coordinator_manager.get_neighbor_map(stub0);
        print("n1 got neighbormap from n0\n");
        for (int i = 0; i < resp.i_coordinator_get_levels(); i++)
        {
            int gsize = resp.i_coordinator_get_gsize(i);
            int free_pos_count = resp.i_coordinator_get_free_pos_count(i);
            print(@"Level $(i) has $(gsize) positions; $(free_pos_count) of them are free in this g-node of level $(i+1).\n");
        }
        for (int lvl_to_join = 1; lvl_to_join <= 4; lvl_to_join++)
        {
            if (resp.i_coordinator_get_free_pos_count(lvl_to_join-1) > 0)
            {
                print(@"n1 tries and get a reservation in g-node $(lvl_to_join) from n0\n");
                get_reservation(n1, stub0, lvl_to_join, resp.i_coordinator_get_levels());
                print(@"n1 tries and get a reservation in g-node $(lvl_to_join) from n0\n");
                get_reservation(n1, stub0, lvl_to_join, resp.i_coordinator_get_levels());
                print(@"n1 tries and get a reservation in g-node $(lvl_to_join) from n0\n");
                get_reservation(n1, stub0, lvl_to_join, resp.i_coordinator_get_levels());
                print(@"n1 tries and get a reservation in g-node $(lvl_to_join) from n0\n");
                get_reservation(n1, stub0, lvl_to_join, resp.i_coordinator_get_levels());
                //print(@"n1 waits for bookings to expire\n");
                //tasklet.ms_wait(25000);
                //print(@"n1 tries and get a reservation in g-node $(lvl_to_join) from n0\n");
                //get_reservation(n1, stub0, lvl_to_join, resp.i_coordinator_get_levels());
            }
            else
            {
                print(@"No space left on $(lvl_to_join) from n0.\n");
            }
        }
    }
    catch (StubNotWorkingError e) {
        error(@"StubNotWorkingError $(e.message)");
    }

    print(@"Now n1 accepts (0,0) from n0.\n");
    // n1 goes to 3.3.0.0
    n1 = new SimulatorNode();
    n1.map_paths = new MyPeersMapPath({4, 4, 4, 4}, {0, 0, 3, 3});
    n1.map_paths.set_fellow(1, /* a fellow of the gnode of level 1 in which we enter as a gnode of level 0. */
                            new MyPeersManagerStub(n0.peers_manager));
    n1.back_factory = new MyPeersBackStubFactory();
    n1.back_factory.add_node(new ArrayList<int>.wrap({1}), n0);
    n0.back_factory.add_node(new ArrayList<int>.wrap({0}), n1);
    n1.neighbor_factory = new MyPeersNeighborsFactory();
    n1.neighbor_factory.neighbors.add(n0);
    n0.neighbor_factory.neighbors.add(n1);
    n1.map = new MyCoordinatorMap({4, 4, 4, 4}, {1, 0, 0, 0});
    n1.map.free_pos[0] = new ArrayList<int>.wrap({2});
    n1.map.free_pos[1] = new ArrayList<int>.wrap({1, 2, 3});
    n1.map.free_pos[2] = new ArrayList<int>.wrap({1, 2});
    n1.map.free_pos[3] = new ArrayList<int>.wrap({0, 1, 2});
    n1.peers_manager = new PeersManager(n1.map_paths,
                             0,  /* a new gnode of level 0 enters into an existing gnode of level 1. */
                             n1.back_factory,
                             n1.neighbor_factory);
    n1.coordinator_manager = new CoordinatorManager(n1.peers_manager, n1.map);
    tasklet.ms_wait(20); // simulate little wait before bootstrap
        n1.map_paths.add_existent_gnode(0, 1, new MyPeersManagerStub(n0.peers_manager));
    n1.coordinator_manager.bootstrap_complete(1);
    tasklet.ms_wait(20); // simulate little wait before ETPs reach fellows
        n0.map.free_pos[0].remove(0);
        n0.map_paths.add_existent_gnode(0, 0, new MyPeersManagerStub(n1.peers_manager));
    n1.coordinator_manager.presence_notified();

    // Another node now asks to n0 to contact its coordinator at level 0. Should be n1.
    var n3 = new SimulatorNode();
    n3.map_paths = new MyPeersMapPath({4, 4, 16}, {2, 3, 12});
    n3.back_factory = new MyPeersBackStubFactory();
    n3.neighbor_factory = new MyPeersNeighborsFactory();
    n3.map = new MyCoordinatorMap({4, 4, 16}, {0, 0, 0});
    // no space left, free_pos are empty.
    n3.peers_manager = new PeersManager(n3.map_paths,
                             3,  /*first node in whole network of 3 levels*/
                             n3.back_factory,
                             n3.neighbor_factory);
    n3.coordinator_manager = new CoordinatorManager(n3.peers_manager, n3.map);
    n3.coordinator_manager.bootstrap_complete(3);
    n3.coordinator_manager.presence_notified();

    tasklet.ms_wait(1000);
    // end
    MyTaskletSystem.kill();
}

void get_reservation
(SimulatorNode asking, MyCoordinatorManagerStub answering, int lvl_to_join, int levels)
throws StubNotWorkingError
{
    try {
        ICoordinatorReservation res = asking.coordinator_manager.get_reservation(answering, lvl_to_join);
        int pos = res.i_coordinator_get_reserved_pos();
        int lvl = res.i_coordinator_get_reserved_lvl();
        assert(lvl == lvl_to_join-1);
        print(@"Ok. Reserved for you position $(pos) at level $(lvl).\n");
        int eldership = res.i_coordinator_get_eldership(lvl);
        print(@"    G-node ($(lvl), $(pos)) has eldership $(eldership) in that network.\n");
        for (int j = lvl+1; j < levels; j++)
        {
            eldership = res.i_coordinator_get_eldership(j);
            print(@"    Its g-node ($(j)) has eldership $(eldership) in that network.\n");
        }
    }
    catch (SaturatedGnodeError e) {
        print(@"Got SaturatedGnodeError while asking at level $(lvl_to_join): $(e.message).\n");
    }
}

public class MyCoordinatorMap : Object, ICoordinatorMap
{
    public MyCoordinatorMap(int[] gsizes, int[] elderships)
    {
        this.gsizes = new ArrayList<int>.wrap(gsizes);
        this.elderships = new ArrayList<int>.wrap(elderships);
        free_pos = new ArrayList<ArrayList<int>>();
        for (int i = 0; i < this.gsizes.size; i++) free_pos.add(new ArrayList<int>());
    }
    public ArrayList<int> gsizes;
    public ArrayList<int> elderships;
    public ArrayList<ArrayList<int>> free_pos;

    public int i_coordinator_get_eldership
    (int lvl)
    {
        return elderships[lvl];
    }

    public Gee.List<int> i_coordinator_get_free_pos
    (int lvl)
    {
        var ret = new ArrayList<int>();
        ret.add_all(free_pos[lvl]);
        return ret;
    }

    public int i_coordinator_get_gsize
    (int lvl)
    {
        return gsizes[lvl];
    }

    public int i_coordinator_get_levels()
    {
        return gsizes.size;
    }
}

public class MyPeersMapPath : Object, IPeersMapPaths
{
    public MyPeersMapPath(int[] gsizes, int[] mypos)
    {
        this.gsizes = new ArrayList<int>.wrap(gsizes);
        this.mypos = new ArrayList<int>.wrap(mypos);
        map_gnodes = new HashMap<string, IPeersManagerStub>();
    }
    public ArrayList<int> gsizes;
    public ArrayList<int> mypos;
    public void add_existent_gnode(int level, int pos, IPeersManagerStub gateway)
    {
        string k = @"$(level),$(pos)";
        map_gnodes[k] = gateway;
    }
    public HashMap<string, IPeersManagerStub> map_gnodes;
    public void set_fellow(int lvl, IPeersManagerStub fellow)
    {
        print(@"Set a fellow for lvl=$(lvl)\n");
        this.fellow = fellow;
    }
    private IPeersManagerStub fellow;

    public bool i_peers_exists
    (int level, int pos)
    {
        string k = @"$(level),$(pos)";
        return map_gnodes.has_key(k);
    }

    public IPeersManagerStub i_peers_fellow
    (int level)
    throws PeersNonexistentFellowError
    {
        print(@"Requested a fellow for lvl=$(level)\n");
        return fellow;
    }

    public IPeersManagerStub i_peers_gateway
    (int level, int pos, zcd.ModRpc.CallerInfo? received_from = null, IPeersManagerStub? failed = null)
    throws PeersNonexistentDestinationError
    {
        string k = @"$(level),$(pos)";
        if (! (map_gnodes.has_key(k))) throw new PeersNonexistentDestinationError.GENERIC(@"gateway not set for $(k)");
        if (received_from == null && failed == null) return map_gnodes[k];
        error("not implemented yet");
    }

    public int i_peers_get_gsize
    (int level)
    {
        return gsizes[level];
    }

    public int i_peers_get_levels()
    {
        return gsizes.size;
    }

    public int i_peers_get_my_pos
    (int level)
    {
        return mypos[level];
    }

    public int i_peers_get_nodes_in_my_group
    (int level)
    {
        return 5; /* a rough estimate */
    }
}

public class MyPeersBackStubFactory : Object, IPeersBackStubFactory
{
    public MyPeersBackStubFactory()
    {
        nodes = new HashMap<string, SimulatorNode>();
    }
    public void add_node(Gee.List<int> positions, SimulatorNode node)
    {
        string s = "*";
        foreach (int pos in positions) s += @",$(pos)";
        nodes[s] = node;
    }
    public HashMap<string, SimulatorNode> nodes;

    public IPeersManagerStub i_peers_get_tcp_inside
    (Gee.List<int> positions)
    {
        string s = "*";
        foreach (int pos in positions) s += @",$(pos)";
        if (nodes.has_key(s))
        {
            return new MyPeersManagerStub(nodes[s].peers_manager);
        }
        else
        {
            return new MyPeersManagerStub(null);
        }
    }
}

public class MyPeersNeighborsFactory : Object, IPeersNeighborsFactory
{
    public MyPeersNeighborsFactory()
    {
        neighbors = new ArrayList<SimulatorNode>();
    }
    public ArrayList<SimulatorNode> neighbors;

    public IPeersManagerStub i_peers_get_broadcast
    (IPeersMissingArcHandler missing_handler)
    {
        var lst = new ArrayList<IPeersManagerSkeleton>();
        foreach (SimulatorNode neighbor in neighbors) lst.add(neighbor.peers_manager);
        MyPeersManagerBroadcastStub ret = new MyPeersManagerBroadcastStub(lst);
        return ret;
    }

    public IPeersManagerStub i_peers_get_tcp
    (IPeersArc arc)
    {
        // this is called only on missed arcs for a previous broadcast message
        error("not implemented yet");
    }
}

public class MyCoordinatorManagerStub : Object, ICoordinatorManagerStub
{
    public bool working;
    public Netsukuku.ModRpc.ICoordinatorManagerSkeleton skeleton;
    public MyCoordinatorManagerStub(ICoordinatorManagerSkeleton skeleton)
    {
        this.skeleton = skeleton;
        working = true;
    }

    public ICoordinatorReservationMessage ask_reservation
    (int lvl)
    throws SaturatedGnodeError, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        return skeleton.ask_reservation(lvl, caller);
    }

    public ICoordinatorNeighborMapMessage retrieve_neighbor_map()
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        return skeleton.retrieve_neighbor_map(caller);
    }
}

public class MyPeersManagerStub : Object, IPeersManagerStub
{
    public bool working;
    public Netsukuku.ModRpc.IPeersManagerSkeleton skeleton;
    public MyPeersManagerStub(IPeersManagerSkeleton? skeleton)
    {
        if (skeleton == null) working = false;
        else
        {
            this.skeleton = skeleton;
            working = true;
        }
    }

    public void forward_peer_message
    (IPeerMessage peer_message)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.forward_peer_message(((IPeerMessage)dup_object(peer_message)), caller);
    }

    public IPeerParticipantSet get_participant_set
    (int lvl)
    throws PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        return skeleton.get_participant_set(lvl, caller);
    }

    public IPeersRequest get_request
    (int msg_id, IPeerTupleNode respondant)
    throws Netsukuku.PeersUnknownMessageError, Netsukuku.PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        return skeleton.get_request(msg_id, ((IPeerTupleNode)dup_object(respondant)), caller);
    }

    public void set_failure
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_failure(msg_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
    }

    public void set_next_destination
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_next_destination(msg_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
    }

    public void set_non_participant
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_non_participant(msg_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
    }

    public void set_participant
    (int p_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_participant(p_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
    }

    public void set_response
    (int msg_id, IPeersResponse response)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_response(msg_id, ((IPeersResponse)dup_object(response)), caller);
    }
}

public class MyPeersManagerBroadcastStub : Object, IPeersManagerStub
{
    public bool working;
    public ArrayList<IPeersManagerSkeleton> skeletons;
    public MyPeersManagerBroadcastStub(Gee.List<IPeersManagerSkeleton> skeletons)
    {
        this.skeletons = new ArrayList<IPeersManagerSkeleton>();
        this.skeletons.add_all(skeletons);
        working = true;
    }

    public void set_participant
    (int p_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        tasklet.ms_wait(2); // simulates network latency
        foreach (IPeersManagerSkeleton skeleton in skeletons)
        {
            var caller = new MyCallerInfo();
            skeleton.set_participant(p_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
        }
    }

    public void forward_peer_message
    (IPeerMessage peer_message)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("forward_peer_message should not be sent in broadcast");
    }

    public IPeerParticipantSet get_participant_set
    (int lvl)
    throws PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("get_participant_set should not be sent in broadcast");
    }

    public IPeersRequest get_request
    (int msg_id, IPeerTupleNode respondant)
    throws PeersUnknownMessageError, PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("forward_peer_message should not be sent in broadcast");
    }

    public void set_failure
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_failure should not be sent in broadcast");
    }

    public void set_next_destination
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_next_destination should not be sent in broadcast");
    }

    public void set_non_participant
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_non_participant should not be sent in broadcast");
    }

    public void set_response
    (int msg_id, IPeersResponse response)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_response should not be sent in broadcast");
    }
}

public class MyCallerInfo : zcd.ModRpc.CallerInfo
{
}

