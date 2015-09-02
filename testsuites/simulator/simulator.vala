using Netsukuku;
using Netsukuku.ModRpc;
using Gee;

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
        int lvl_to_join = 1;
        if (resp.i_coordinator_get_free_pos_count(lvl_to_join-1) > 0)
        {
            print(@"n1 tries and get a reservation in g-node $(lvl_to_join) from n0\n");
            try {
                ICoordinatorReservation res = n1.coordinator_manager.get_reservation(stub0, lvl_to_join);
                int pos = res.i_coordinator_get_reserved_pos();
                int lvl = res.i_coordinator_get_reserved_lvl();
                assert(lvl == lvl_to_join-1);
                print(@"Ok. Reserved for you position $(pos) at level $(lvl).\n");
            }
            catch (SaturatedGnodeError e) {
                print(@"No space left on $(lvl_to_join) because of some bookings.\n");
            }
        }
        else
        {
            print(@"No space left on $(lvl_to_join) from n0.\n");
        }
    }
    catch (StubNotWorkingError e) {
        error(@"StubNotWorkingError $(e.message)");
    }

    tasklet.ms_wait(1000);
    // end
    MyTaskletSystem.kill();
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
        return free_pos[lvl];
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
        error("not implemented yet");
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
        error("not implemented yet");
    }
}

public class MyPeersBackStubFactory : Object, IPeersBackStubFactory
{
    public IPeersManagerStub i_peers_get_tcp_inside
    (Gee.List<int> positions)
    {
        error("not implemented yet");
    }
}

public class MyPeersNeighborsFactory : Object, IPeersNeighborsFactory
{
    public IPeersManagerStub i_peers_get_broadcast
    (IPeersMissingArcHandler missing_handler)
    {
        error("not implemented yet");
    }

    public IPeersManagerStub i_peers_get_tcp
    (IPeersArc arc)
    {
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
        return skeleton.ask_reservation(lvl, caller);
    }

    public ICoordinatorNeighborMapMessage retrieve_neighbor_map()
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        return skeleton.retrieve_neighbor_map(caller);
    }
}

public class MyCallerInfo : zcd.ModRpc.CallerInfo
{
}

