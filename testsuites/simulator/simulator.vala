/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
 *
 *  Netsukuku is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Netsukuku is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Netsukuku.  If not, see <http://www.gnu.org/licenses/>.
 */

using Netsukuku;
using Netsukuku.ModRpc;
using Gee;

namespace debugging
{
    string list_int(Gee.List<int> a)
    {
        string next = "";
        string ret = "";
        foreach (int i in a)
        {
            ret += @"$(next)$(i)";
            next = ", ";
        }
        return @"[$(ret)]";
    }
}

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
    Type type = obj.get_type();
    string t = json_string_object(obj);
    Json.Parser p = new Json.Parser();
    try {
        assert(p.load_from_data(t));
    } catch (Error e) {assert_not_reached();}
    Object ret = Json.gobject_deserialize(type, p.get_root());
    return ret;
}

public class SimulatorNode : Object
{
    public string name;
    public Gee.List<int> my_pos;
    public Gee.List<int> elderships;
    public Gee.List<string> neighbors;
    public MyPeersMapPath map_paths;
    public MyPeersBackStubFactory back_factory;
    public MyPeersNeighborsFactory neighbor_factory;
    public MyCoordinatorMap map;
    public PeersManager peers_manager;
    public CoordinatorManager coordinator_manager;
}

INtkdTasklet tasklet;
void main(string[] args)
{
    // init tasklet
    MyTaskletSystem.init();
    tasklet = MyTaskletSystem.get_ntkd();

    // pass tasklet system to modules
    PeersManager.init(tasklet);
    CoordinatorManager.init(tasklet);

    var t = new FileTester();
    t.test_file(args[1]);

    // end
    MyTaskletSystem.kill();
}

class Directive : Object
{
    // Activate a neighbor
    public bool activate_neighbor = false;
    public string an_name;
    public string an_neighbor_name;
    public int an_lvl;
    public int an_pos;
    public Gee.List<int> an_upper_elderships;
    public Gee.List<int> an_lower_pos;
    // Wait
    public bool wait = false;
    public int wait_msec;
    // Info
    public bool info = false;
    public string info_name;
    // Reserve a place: will obtain a pos and list of upper elderships.
    public bool request_reserve = false;
    public string rr_query_node_name;
    public int rr_lvl;
    public bool rr_expect_ok = false;
    public bool rr_expect_notready = false;
    public bool rr_expect_invalid = false;
    public bool rr_expect_saturated = false;
    public bool rr_activate_next = false;
    public Directive rr_next;
}

string[] read_file(string path)
{
    string[] ret = new string[0];
    if (FileUtils.test(path, FileTest.EXISTS))
    {
        try {
            string contents;
            assert(FileUtils.get_contents(path, out contents));
            ret = contents.split("\n");
        } catch (FileError e) {
            error(@"$(e.domain.to_string()): $(e.code): $(e.message)");
        }
    }
    else error(@"Script $(path) not found");
    return ret;
}

internal class FileTester : Object
{
    int levels;
    ArrayList<int> gsizes;
    HashMap<string, SimulatorNode> nodes;

    public void test_file(string fname)
    {
        // read data
        gsizes = new ArrayList<int>();
        nodes = new HashMap<string, SimulatorNode>();
        ArrayList<Directive> directives = new ArrayList<Directive>();
        string[] data = read_file(fname);
        int data_cur = 0;

        while (data[data_cur] != "topology") data_cur++;
        data_cur++;
        string s_topology = data[data_cur++];
        string[] s_topology_pieces = s_topology.split(" ");
        levels = s_topology_pieces.length;
        foreach (string s_piece in s_topology_pieces) gsizes.insert(0, int.parse(s_piece));

        while (data[data_cur] != "first_node") data_cur++;
        data_cur++;
        string s_first_node = data[data_cur++];
        string[] s_first_node_pieces = s_first_node.split(" ");
        assert(levels == s_first_node_pieces.length);
        string first_node_name = "first_node";
        {
            nodes[first_node_name] = new SimulatorNode();
            SimulatorNode n = nodes[first_node_name];
            n.name = first_node_name;
            n.my_pos = new ArrayList<int>();
            n.elderships = new ArrayList<int>();
            for (int i = 0; i < levels; i++)
            {
                n.my_pos.insert(0, int.parse(s_first_node_pieces[i]));
                n.elderships.add(0);
            }
            n.neighbors = new ArrayList<string>();
            n.map_paths = new MyPeersMapPath(gsizes.to_array(), n.my_pos.to_array());
            n.back_factory = new MyPeersBackStubFactory();
            n.neighbor_factory = new MyPeersNeighborsFactory();
            n.coordinator_manager = new CoordinatorManager(levels);
            // after bootstrap phase of qspn:
            n.peers_manager = new PeersManager(n.map_paths,
                                     levels,
                                     n.back_factory,
                                     n.neighbor_factory);
            n.map = new MyCoordinatorMap(gsizes, n.my_pos, n.elderships);
            n.coordinator_manager.bootstrap_completed(n.peers_manager, n.map);
        }

        while (true)
        {
            if (data[data_cur] != null && data[data_cur].has_prefix("add_neighbor"))
            {
                Directive dd = new Directive();
                dd.activate_neighbor = true;
                string line = data[data_cur];
                string[] line_pieces = line.split(" ");
                dd.an_name = line_pieces[1];
                assert(line_pieces[2] == "to");
                dd.an_neighbor_name = line_pieces[3];
                assert(line_pieces.length == 4);
                directives.add(dd);
                data_cur++;
                while (data[data_cur] != "")
                {
                    if (data[data_cur].has_prefix("lower_pos"))
                    {
                        line = data[data_cur];
                        line_pieces = line.split(" ");
                        dd.an_lvl = line_pieces.length - 1;
                        dd.an_pos = int.parse(line_pieces[1]);
                        dd.an_lower_pos = new ArrayList<int>();
                        for (int i = 2; i < line_pieces.length; i++)
                        {
                            dd.an_lower_pos.insert(0, int.parse(line_pieces[i]));
                        }
                    }
                    else if (data[data_cur].has_prefix("elderships"))
                    {
                        line = data[data_cur];
                        line_pieces = line.split(" ");
                        dd.an_upper_elderships = new ArrayList<int>();
                        for (int i = 1; i < line_pieces.length; i++)
                        {
                            dd.an_upper_elderships.insert(0, int.parse(line_pieces[i]));
                        }
                    }
                    else error(@"malformed file at line $(data_cur)");
                    data_cur++;
                }
                assert(data[data_cur] == "");
            }
            else if (data[data_cur] != null && data[data_cur].has_prefix("wait_msec"))
            {
                string line = data[data_cur];
                string[] line_pieces = line.split(" ");
                int wait_msec = int.parse(line_pieces[1]);
                // data input done
                Directive dd = new Directive();
                dd.wait = true;
                dd.wait_msec = wait_msec;
                directives.add(dd);
                data_cur++;
                assert(data[data_cur] == "");
            }
            else if (data[data_cur] != null && data[data_cur].has_prefix("print_info"))
            {
                string line = data[data_cur];
                string[] line_pieces = line.split(" ");
                string info_name = line_pieces[1];
                // data input done
                Directive dd = new Directive();
                dd.info = true;
                dd.info_name = info_name;
                directives.add(dd);
                data_cur++;
                assert(data[data_cur] == "");
            }
            else if (data[data_cur] != null && data[data_cur].has_prefix("request_reserve"))
            {
                string line = data[data_cur];
                string[] line_pieces = line.split(" ");
                Directive dd = new Directive();
                dd.request_reserve = true;
                assert(line_pieces[1] == "to");
                dd.rr_query_node_name = line_pieces[2];
                assert(line_pieces[3] == "level");
                dd.rr_lvl = int.parse(line_pieces[4]);
                assert(line_pieces.length == 5);
                directives.add(dd);
                data_cur++;
                while (data[data_cur] != "")
                {
                    if (data[data_cur].has_prefix("expect"))
                    {
                        line = data[data_cur];
                        line_pieces = line.split(" ");
                        assert(line_pieces.length == 2);
                        if (line_pieces[1] == "ok") dd.rr_expect_ok = true;
                        else if (line_pieces[1] == "invalid_level") dd.rr_expect_invalid = true;
                        else if (line_pieces[1] == "node_not_ready") dd.rr_expect_notready = true;
                        else if (line_pieces[1] == "saturated_gnode") dd.rr_expect_saturated = true;
                        else error(@"malformed file at line $(data_cur)");
                    }
                    else if (data[data_cur].has_prefix("accept"))
                    {
                        line = data[data_cur];
                        line_pieces = line.split(" ");
                        assert(line_pieces.length > 2);
                        Directive dd2 = new Directive();
                        dd.rr_activate_next = true;
                        dd.rr_next = dd2;
                        dd2.activate_neighbor = true;
                        dd2.an_name = line_pieces[1];
                        assert(line_pieces[2] == "lower_pos");
                        dd2.an_neighbor_name = dd.rr_query_node_name;
                        dd2.an_lvl = dd.rr_lvl - 1;
                        dd2.an_lower_pos = new ArrayList<int>();
                        for (int i = 3; i < line_pieces.length; i++)
                        {
                            dd2.an_lower_pos.insert(0, int.parse(line_pieces[i]));
                        }
                        directives.add(dd2);
                    }
                    else error(@"malformed file at line $(data_cur)");
                    data_cur++;
                }
                assert(data[data_cur] == "");
            }
            else if (data_cur >= data.length)
            {
                break;
            }
            else
            {
                data_cur++;
            }
        }

        // execute directives
        foreach (Directive dd in directives)
        {
            if (dd.request_reserve)
            {
                var neighbor_n = nodes[dd.rr_query_node_name];
                // A temporary node now asks to neighbor_n to contact its coordinator at level dd.rr_lvl.
                var tempnode = new SimulatorNode();
                tempnode.name = "temp";
                tempnode.my_pos = new ArrayList<int>();
                tempnode.elderships = new ArrayList<int>();
                for (int i = 0; i < levels; i++)
                {
                    tempnode.my_pos.insert(0, int.parse(s_first_node_pieces[i]));
                    tempnode.elderships.add(0);
                }
                tempnode.neighbors = new ArrayList<string>();
                tempnode.map_paths = new MyPeersMapPath({4, 4, 4} /*gsizes*/,
                                                        {2, 3, 2} /*my_pos*/);
                tempnode.back_factory = new MyPeersBackStubFactory();
                tempnode.neighbor_factory = new MyPeersNeighborsFactory();
                tempnode.coordinator_manager = new CoordinatorManager(3 /*levels*/);
                // after bootstrap phase of qspn:
                tempnode.peers_manager = new PeersManager(tempnode.map_paths,
                                         3 /*levels*/,
                                         tempnode.back_factory,
                                         tempnode.neighbor_factory);
                tempnode.map = new MyCoordinatorMap(new ArrayList<int>.wrap({4, 4, 4}) /*gsizes*/,
                                                    new ArrayList<int>.wrap({2, 3, 2}) /*my_pos*/,
                                                    new ArrayList<int>.wrap({0, 0, 0}) /*elderships*/);
                tempnode.coordinator_manager.bootstrap_completed(tempnode.peers_manager, tempnode.map);
                ICoordinatorReservation res;
                try {
                    var stub_c = new MyCoordinatorManagerTcpStub(neighbor_n.coordinator_manager);
                    print("start get_reservation.\n");
                    res = get_reservation(tempnode, stub_c, dd.rr_lvl);
                    print("finish get_reservation.\n");
                    if (dd.rr_expect_invalid) error("Got ok, expected invalid_level.");
                    if (dd.rr_expect_notready) error("Got ok, expected node_not_ready.");
                    if (dd.rr_expect_saturated) error("Got ok, expected saturated_gnode.");
                    if (dd.rr_activate_next)
                    {
                        assert(levels == res.get_levels());
                        for (int i = 0; i < gsizes.size; i++)
                            assert(gsizes[i] == res.get_gsize(i));
                        int lvl = res.get_lvl();
                        int pos = res.get_pos();
                        int eldership = res.get_eldership();
                        Directive dd2 = dd.rr_next;
                        dd2.an_pos = pos;
                        dd2.an_lvl = lvl+1;
                        dd2.an_upper_elderships = new ArrayList<int>();
                        dd2.an_upper_elderships.add(eldership);
                        for (int i = lvl+1; i < levels; i++)
                        {
                            dd2.an_upper_elderships.add(res.get_upper_eldership(i));
                        }
                    }
                }
                catch (CoordinatorStubNotWorkingError e) {
                    error(@"CoordinatorStubNotWorkingError $(e.message)");
                }
                catch (CoordinatorNodeNotReadyError e) {
                    if (dd.rr_expect_ok) error(@"CoordinatorNodeNotReadyError $(e.message)");
                    if (dd.rr_activate_next) error(@"CoordinatorNodeNotReadyError $(e.message)");
                    if (dd.rr_expect_invalid) error(@"CoordinatorNodeNotReadyError $(e.message)");
                    if (dd.rr_expect_saturated) error(@"CoordinatorNodeNotReadyError $(e.message)");
                }
                catch (CoordinatorInvalidLevelError e) {
                    if (dd.rr_expect_ok) error(@"CoordinatorInvalidLevelError $(e.message)");
                    if (dd.rr_activate_next) error(@"CoordinatorInvalidLevelError $(e.message)");
                    if (dd.rr_expect_notready) error(@"CoordinatorInvalidLevelError $(e.message)");
                    if (dd.rr_expect_saturated) error(@"CoordinatorInvalidLevelError $(e.message)");
                }
                catch (CoordinatorSaturatedGnodeError e) {
                    if (dd.rr_expect_ok) error(@"CoordinatorSaturatedGnodeError $(e.message)");
                    if (dd.rr_activate_next) error(@"CoordinatorSaturatedGnodeError $(e.message)");
                    if (dd.rr_expect_invalid) error(@"CoordinatorSaturatedGnodeError $(e.message)");
                    if (dd.rr_expect_notready) error(@"CoordinatorSaturatedGnodeError $(e.message)");
                }
            }
            else if (dd.activate_neighbor)
            {
                assert(dd.an_lvl <= levels);
                assert(dd.an_lvl > 0);
                var neighbor_n = nodes[dd.an_neighbor_name];
                while (neighbor_n.peers_manager == null) tasklet.ms_wait(10);
                nodes[dd.an_name] = new SimulatorNode();
                SimulatorNode n = nodes[dd.an_name];
                n.name = dd.an_name;
                n.my_pos = new ArrayList<int>();
                n.elderships = new ArrayList<int>();
                for (int i = 0; i < dd.an_lvl-1; i++)
                {
                    n.my_pos.add(dd.an_lower_pos[i]);
                    n.elderships.add(0);
                }
                n.my_pos.add(dd.an_pos);
                n.elderships.add(dd.an_upper_elderships[0]);
                for (int i = dd.an_lvl; i < levels; i++)
                {
                    n.my_pos.add(neighbor_n.my_pos[i]);
                    n.elderships.add(dd.an_upper_elderships[1+i-dd.an_lvl]);
                }
                n.neighbors = new ArrayList<string>();
                n.map_paths = new MyPeersMapPath(gsizes.to_array(), n.my_pos.to_array());
                n.back_factory = new MyPeersBackStubFactory();
                n.neighbor_factory = new MyPeersNeighborsFactory();
                n.map = new MyCoordinatorMap(gsizes, n.my_pos, n.elderships);
                n.map_paths.set_fellow(dd.an_lvl, new MyPeersManagerTcpFellowStub(neighbor_n.peers_manager));
                n.peers_manager = new PeersManager(n.map_paths,
                                         dd.an_lvl-1,  /*level of new gnode*/
                                         n.back_factory,
                                         n.neighbor_factory);
                n.coordinator_manager = new CoordinatorManager(dd.an_lvl-1);
                n.neighbors.add(dd.an_neighbor_name);
                neighbor_n.neighbors.add(dd.an_name);
                // continue in a tasklet
                CompleteHookTasklet ts = new CompleteHookTasklet();
                ts.t = this;
                ts.dd = dd;
                tasklet.spawn(ts);
            }
            else if (dd.wait)
            {
                print(@"waiting $(dd.wait_msec) msec...\n");
                tasklet.ms_wait(dd.wait_msec);
            }
            else if (dd.info)
            {
                print(@"examining node $(dd.info_name).\n"); //TODO
                assert(nodes.has_key(dd.info_name));
                SimulatorNode n = nodes[dd.info_name];
                string mypos = "";
                string mypos_next = "";
                foreach (int p in n.my_pos)
                {
                    mypos += @"$(mypos_next)$(p)";
                    mypos_next = ", ";
                }
                print(@"  my_pos: $(mypos)\n");
                print(@"  map:\n");
                int n_levels = n.map.get_levels();
                print(@"    levels = $(n_levels)\n");
                string next = "";
                print("    elderships = [");
                for (int i = 0; i < n_levels; i++)
                {
                    int n_eldership = n.map.get_eldership(i);
                    print(@"$(next)$(n_eldership)");
                    next = ", ";
                }
                print("]\n");
                next = "";
                print("    my_pos = [");
                for (int i = 0; i < n_levels; i++)
                {
                    int n_my_pos = n.map.get_my_pos(i);
                    print(@"$(next)$(n_my_pos)");
                    next = ", ";
                }
                print("]\n");
                for (int i = 0; i < n_levels; i++)
                {
                    string n_free_pos = debugging.list_int(n.map.get_free_pos(i));
                    print(@"    free_pos #$(i) = $(n_free_pos)\n");
                }
                print("\n");
            }
            else error("not implemented yet");
        }
    }
    internal class CompleteHookTasklet : Object, INtkdTaskletSpawnable
    {
        public FileTester t;
        public Directive dd;
        public void * func()
        {
            t.tasklet_complete_hook(dd);
            return null;
        }
    }
    private void tasklet_complete_hook(Directive dd)
    {
        tasklet.ms_wait(20); // simulate little wait before bootstrap
        update_my_map(dd.an_neighbor_name, dd.an_name);
        update_back_factories(dd.an_name);
        SimulatorNode n = nodes[dd.an_name];
        n.coordinator_manager.bootstrap_completed(n.peers_manager, n.map);
        tasklet.ms_wait(100); // simulate little wait before ETPs reach fellows
        start_update_their_maps(dd.an_neighbor_name, dd.an_name);
    }

    void update_back_factories(string name)
    {
        SimulatorNode neo = nodes[name];
        foreach (string name_other in nodes.keys) if (name_other != name)
        {
            SimulatorNode other = nodes[name_other];
            int max_distinct_level = levels-1;
            while (neo.my_pos[max_distinct_level] == other.my_pos[max_distinct_level]) max_distinct_level--;
            int min_common_level = max_distinct_level + 1;
            var positions_neo = new ArrayList<int>();
            var positions_other = new ArrayList<int>();
            for (int j = 0; j < min_common_level; j++)
            {
                positions_neo.add(neo.my_pos[j]);
                positions_other.add(other.my_pos[j]);
            }
            neo.back_factory.add_node(positions_other, other);
            other.back_factory.add_node(positions_neo, neo);
        }
    }

    void update_my_map(string neighbor_name, string name)
    {
        SimulatorNode gw = nodes[neighbor_name];
        SimulatorNode neo = nodes[name];
        int gw_lvl = levels-1;
        while (gw.my_pos[gw_lvl] == neo.my_pos[gw_lvl])
        {
            gw_lvl--;
            assert(gw_lvl >= 0);
        }
        if (neo.map.free_pos[gw_lvl].contains(gw.my_pos[gw_lvl]))
            neo.map.free_pos[gw_lvl].remove(gw.my_pos[gw_lvl]);
        neo.map_paths.add_existent_gnode(gw_lvl, gw.my_pos[gw_lvl], new MyPeersManagerTcpNoWaitStub(gw.peers_manager));
        for (int i = gw_lvl; i < levels; i++)
        {
            for (int j = 0; j < gsizes[i]; j++)
            {
                if (j != gw.my_pos[i])
                {
                    if (gw.map_paths.i_peers_exists(i, j))
                    {
                        if (neo.map.free_pos[i].contains(j))
                            neo.map.free_pos[i].remove(j);
                        neo.map_paths.add_existent_gnode(i, j, new MyPeersManagerTcpNoWaitStub(gw.peers_manager));
                    }
                }
            }
        }
    }

    void start_update_their_maps(string neighbor_name, string name)
    {
        update_their_maps(neighbor_name, name, name);
    }

    void update_their_maps(string name_old, string name_neo, string name_gw_to_neo)
    {
        SimulatorNode old = nodes[name_old];
        SimulatorNode neo = nodes[name_neo];
        SimulatorNode gw_to_neo = nodes[name_gw_to_neo];
        int neo_lvl = levels-1;
        while (neo.my_pos[neo_lvl] == old.my_pos[neo_lvl])
        {
            neo_lvl--;
            assert(neo_lvl >= 0);
        }
        int neo_pos = neo.my_pos[neo_lvl];
        if (! old.map_paths.i_peers_exists(neo_lvl, neo_pos))
        {
            old.map_paths.add_existent_gnode(neo_lvl, neo_pos, new MyPeersManagerTcpNoWaitStub(gw_to_neo.peers_manager));
        }
        if (old.map.free_pos[neo_lvl].contains(neo_pos))
        {
            old.map.free_pos[neo_lvl].remove(neo_pos);
        }
        foreach (string neighbor_name in old.neighbors) if (neighbor_name != name_gw_to_neo)
        {
            update_their_maps(neighbor_name, name_neo, name_old);
        }
    }
}

// helper
ICoordinatorReservation get_reservation
(SimulatorNode asking, MyCoordinatorManagerTcpStub answering, int lvl_to_join)
throws CoordinatorStubNotWorkingError,
       CoordinatorInvalidLevelError,
       CoordinatorNodeNotReadyError,
       CoordinatorSaturatedGnodeError
{
    try {
        ICoordinatorReservation res = asking.coordinator_manager.get_reservation(answering, lvl_to_join);
        int levels = res.get_levels();
        int lvl = res.get_lvl();
        int pos = res.get_pos();
        int eldership = res.get_eldership();
        assert(lvl == lvl_to_join-1);
        print(@"Ok. Reserved for you position $(pos) at level $(lvl) with eldership $(eldership).\n");
        for (int j = lvl+1; j < levels; j++)
        {
            pos = res.get_upper_pos(j);
            eldership = res.get_upper_eldership(j);
            print(@"              inside position $(pos) at level $(j) with eldership $(eldership).\n");
        }
        return res;
    }
    catch (CoordinatorSaturatedGnodeError e) {
        print(@"Got SaturatedGnodeError while asking at level $(lvl_to_join): $(e.message).\n");
        throw e;
    }
}

public class MyCoordinatorMap : Object, ICoordinatorMap
{
    public MyCoordinatorMap(Gee.List<int> gsizes, Gee.List<int> my_pos, Gee.List<int> elderships)
    {
        assert(gsizes.size != 0);
        levels = gsizes.size;
        assert(my_pos.size == levels);
        assert(elderships.size == levels);
        this.gsizes = new ArrayList<int>();
        this.gsizes.add_all(gsizes);
        this.my_pos = new ArrayList<int>();
        this.my_pos.add_all(my_pos);
        this.elderships = new ArrayList<int>();
        this.elderships.add_all(elderships);
        free_pos = new ArrayList<ArrayList<int>>();
        for (int i = 0; i < levels; i++)
        {
            free_pos.add(new ArrayList<int>());
            for (int j = 0; j < gsizes[i]; j++)
            {
                if (j != my_pos[i]) free_pos[i].add(j);
            }
        }
    }
    public int levels;
    public ArrayList<int> gsizes;
    public ArrayList<int> my_pos;
    public ArrayList<int> elderships;
    public ArrayList<ArrayList<int>> free_pos;

    public int get_eldership
    (int lvl)
    {
        return elderships[lvl];
    }

    public int get_my_pos
    (int lvl)
    {
        return my_pos[lvl];
    }

    public Gee.List<int> get_free_pos
    (int lvl)
    {
        var ret = new ArrayList<int>();
        ret.add_all(free_pos[lvl]);
        return ret;
    }

    public int get_gsize
    (int lvl)
    {
        return gsizes[lvl];
    }

    public int get_levels()
    {
        return gsizes.size;
    }
}

public class MyPeersMapPath : Object, IPeersMapPaths
{
    public MyPeersMapPath(int[] gsizes, int[] mypos)
    {
        this.gsizes = new ArrayList<int>();
        this.gsizes.add_all_array(gsizes);
        this.mypos = new ArrayList<int>();
        this.mypos.add_all_array(mypos);
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
        return fellow;
    }

    public IPeersManagerStub i_peers_gateway
    (int level, int pos, zcd.ModRpc.CallerInfo? received_from = null, IPeersManagerStub? failed = null)
    throws PeersNonexistentDestinationError
    {
        string k = @"$(level),$(pos)";
        if (! (map_gnodes.has_key(k)))
        {
            warning(@"Transmitting a peer-message. gateway not set for $(k).");
            throw new PeersNonexistentDestinationError.GENERIC(@"gateway not set for $(k)");
        }
        // This simulator has a lazy implementation of i_peers_gateway. It simulates well only networks with no loops.
        if (failed != null) error("not implemented yet");
        return map_gnodes[k];
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
        if (level == 0) return 1;
        // approssimative implementation, it should be ok
        return 20;
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
        string s = "";
        foreach (int pos in positions)
        {
            s += @"$(pos),";
        }
        s += "*";
        nodes[s] = node;
    }
    public HashMap<string, SimulatorNode> nodes;

    public IPeersManagerStub i_peers_get_tcp_inside
    (Gee.List<int> positions)
    {
        string s = "";
        foreach (int pos in positions)
        {
            s += @"$(pos),";
        }
        s += "*";
        if (nodes.has_key(s))
        {
            return new MyPeersManagerTcpInsideStub(nodes[s].peers_manager);
        }
        else
        {
            return new MyPeersManagerTcpInsideStub(null);
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

public class MyCoordinatorManagerTcpStub : Object, ICoordinatorManagerStub
{
    public bool working;
    public Netsukuku.ModRpc.ICoordinatorManagerSkeleton skeleton;
    public MyCoordinatorManagerTcpStub(ICoordinatorManagerSkeleton skeleton)
    {
        this.skeleton = skeleton;
        working = true;
    }

    public ICoordinatorReservationMessage ask_reservation
    (int lvl)
    throws CoordinatorNodeNotReadyError, CoordinatorInvalidLevelError, CoordinatorSaturatedGnodeError,
           zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        ICoordinatorReservationMessage ret = skeleton.ask_reservation(lvl, caller);
        return (ICoordinatorReservationMessage)dup_object(ret);
    }

    public ICoordinatorNeighborMapMessage retrieve_neighbor_map()
    throws CoordinatorNodeNotReadyError, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        ICoordinatorNeighborMapMessage ret = skeleton.retrieve_neighbor_map(caller);
        return (ICoordinatorNeighborMapMessage)dup_object(ret);
    }
}

public class MyPeersManagerTcpFellowStub : Object, IPeersManagerStub
{
    public bool working;
    public Netsukuku.ModRpc.IPeersManagerSkeleton skeleton;
    public MyPeersManagerTcpFellowStub(IPeersManagerSkeleton skeleton)
    {
        this.skeleton = skeleton;
        working = true;
    }

    public void forward_peer_message
    (IPeerMessage peer_message)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("forward_peer_message should not be sent in tcp-fellow");
    }

    public IPeerParticipantSet get_participant_set
    (int lvl)
    throws PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug("calling get_participant_set...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        debug("executing get_participant_set...\n");
        IPeerParticipantSet ret = skeleton.get_participant_set(lvl, caller);
        debug("returning data from get_participant_set.\n");
        return (IPeerParticipantSet)dup_object(ret);
    }

    public IPeersRequest get_request
    (int msg_id, IPeerTupleNode respondant)
    throws Netsukuku.PeersUnknownMessageError, Netsukuku.PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("get_request should not be sent in tcp-fellow");
    }

    public void set_failure
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_failure should not be sent in tcp-fellow");
    }

    public void set_next_destination
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_next_destination should not be sent in tcp-fellow");
    }

    public void set_non_participant
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_non_participant should not be sent in tcp-fellow");
    }

    public void set_participant
    (int p_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_participant should not be sent in tcp-fellow");
    }

    public void set_redo_from_start
    (int msg_id, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_redo_from_start should not be sent in tcp-fellow");
    }

    public void set_refuse_message
    (int msg_id, string refuse_message, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_refuse_message should not be sent in tcp-fellow");
    }

    public void set_response
    (int msg_id, IPeersResponse response, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_response should not be sent in tcp-fellow");
    }
}

public class MyPeersManagerTcpNoWaitStub : Object, IPeersManagerStub
{
    public bool working;
    public Netsukuku.ModRpc.IPeersManagerSkeleton skeleton;
    public MyPeersManagerTcpNoWaitStub(IPeersManagerSkeleton skeleton)
    {
        this.skeleton = skeleton;
        working = true;
    }

    public void forward_peer_message
    (IPeerMessage peer_message)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"calling forward_peer_message $(peer_message.get_type().name())...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        // in a new tasklet...
        ForwardPeerMessageTasklet ts = new ForwardPeerMessageTasklet();
        ts.t = this;
        ts.peer_message = (IPeerMessage)dup_object(peer_message);
        ts.caller = caller;
        tasklet.spawn(ts);
        debug("returning void from forward_peer_message.\n");
    }
    private class ForwardPeerMessageTasklet : Object, INtkdTaskletSpawnable
    {
        public MyPeersManagerTcpNoWaitStub t;
        public IPeerMessage peer_message;
        public MyCallerInfo caller;
        public void * func()
        {
            t.tasklet_forward_peer_message(peer_message, caller);
            return null;
        }
    }
    private void tasklet_forward_peer_message(IPeerMessage peer_message, MyCallerInfo caller)
    {
        debug("executing forward_peer_message...\n");
        skeleton.forward_peer_message(peer_message, caller);
    }

    public IPeerParticipantSet get_participant_set
    (int lvl)
    throws PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("get_participant_set should not be sent in tcp-nowait");
    }

    public IPeersRequest get_request
    (int msg_id, IPeerTupleNode respondant)
    throws Netsukuku.PeersUnknownMessageError, Netsukuku.PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("get_request should not be sent in tcp-nowait");
    }

    public void set_failure
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_failure should not be sent in tcp-nowait");
    }

    public void set_next_destination
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_next_destination should not be sent in tcp-nowait");
    }

    public void set_non_participant
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_non_participant should not be sent in tcp-nowait");
    }

    public void set_participant
    (int p_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_participant should not be sent in tcp-nowait");
    }

    public void set_redo_from_start
    (int msg_id, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_redo_from_start should not be sent in tcp-nowait");
    }

    public void set_refuse_message
    (int msg_id, string refuse_message, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_refuse_message should not be sent in tcp-nowait");
    }

    public void set_response
    (int msg_id, IPeersResponse response, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_response should not be sent in tcp-nowait");
    }
}

public class MyPeersManagerTcpInsideStub : Object, IPeersManagerStub
{
    public bool working;
    public Netsukuku.ModRpc.IPeersManagerSkeleton skeleton;
    public MyPeersManagerTcpInsideStub(IPeersManagerSkeleton? skeleton)
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
        error("forward_peer_message should not be sent in tcp-inside");
    }

    public IPeerParticipantSet get_participant_set
    (int lvl)
    throws PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("get_participant_set should not be sent in tcp-inside");
    }

    public IPeersRequest get_request
    (int msg_id, IPeerTupleNode respondant)
    throws Netsukuku.PeersUnknownMessageError, Netsukuku.PeersInvalidRequest, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"sending to caller 'get_request' msg_id=$(msg_id)...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        IPeersRequest ret = skeleton.get_request(msg_id, ((IPeerTupleNode)dup_object(respondant)), caller);
        return (IPeersRequest)dup_object(ret);
    }

    public void set_failure
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"sending to caller 'set_failure' msg_id=$(msg_id)...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_failure(msg_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
    }

    public void set_next_destination
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"sending to caller 'set_next_destination' msg_id=$(msg_id)...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_next_destination(msg_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
    }

    public void set_non_participant
    (int msg_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"sending to caller 'set_non_participant' msg_id=$(msg_id)...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_non_participant(msg_id, ((IPeerTupleGNode)dup_object(tuple)), caller);
    }

    public void set_participant
    (int p_id, IPeerTupleGNode tuple)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_participant should not be sent in tcp-inside");
    }

    public void set_redo_from_start
    (int msg_id, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"sending to caller 'set_redo_from_start' msg_id=$(msg_id)...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_redo_from_start(msg_id, ((IPeerTupleNode)dup_object(respondant)), caller);
    }

    public void set_refuse_message
    (int msg_id, string refuse_message, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"sending to caller 'set_refuse_message' msg_id=$(msg_id)...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_refuse_message(msg_id, refuse_message, ((IPeerTupleNode)dup_object(respondant)), caller);
    }

    public void set_response
    (int msg_id, IPeersResponse response, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        debug(@"sending to caller 'set_response' msg_id=$(msg_id)...\n");
        if (!working) throw new zcd.ModRpc.StubError.GENERIC("not working");
        var caller = new MyCallerInfo();
        tasklet.ms_wait(2); // simulates network latency
        skeleton.set_response(msg_id, ((IPeersResponse)dup_object(response)), ((IPeerTupleNode)dup_object(respondant)), caller);
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
            // in a new tasklet...
            SetParticipantTasklet ts = new SetParticipantTasklet();
            ts.t = this;
            ts.skeleton = skeleton;
            ts.p_id = p_id;
            ts.tuple = (IPeerTupleGNode)dup_object(tuple);
            ts.caller = caller;
            tasklet.spawn(ts);
        }
    }
    private class SetParticipantTasklet : Object, INtkdTaskletSpawnable
    {
        public MyPeersManagerBroadcastStub t;
        public IPeersManagerSkeleton skeleton;
        public int p_id;
        public IPeerTupleGNode tuple;
        public MyCallerInfo caller;
        public void * func()
        {
            t.tasklet_set_participant(skeleton, p_id, tuple, caller);
            return null;
        }
    }
    private void tasklet_set_participant(IPeersManagerSkeleton skeleton, int p_id, IPeerTupleGNode tuple, MyCallerInfo caller)
    {
        skeleton.set_participant(p_id, tuple, caller);
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

    public void set_redo_from_start
    (int msg_id, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_redo_from_start should not be sent in broadcast");
    }

    public void set_refuse_message
    (int msg_id, string refuse_message, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_refuse_message should not be sent in broadcast");
    }

    public void set_response
    (int msg_id, IPeersResponse response, IPeerTupleNode respondant)
    throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("set_response should not be sent in broadcast");
    }
}

public class MyCallerInfo : zcd.ModRpc.CallerInfo
{
}

