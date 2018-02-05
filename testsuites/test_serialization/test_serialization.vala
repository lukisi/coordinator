/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2018 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

using Gee;
using Netsukuku;
using Netsukuku.Coordinator;

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

class CoordTester : Object
{
    public void set_up ()
    {
    }

    public void tear_down ()
    {
    }

    public void test_timer()
    {
        {
            SerTimer t0;
            {
                Json.Node node;
                {
                    SerTimer t = new SerTimer(20);
                    node = Json.gobject_serialize(t);
                }
                t0 = (SerTimer)Json.gobject_deserialize(typeof(SerTimer), node);
            }
            assert(! t0.is_expired());
        }
        {
            SerTimer t0;
            {
                Json.Node node;
                {
                    SerTimer t = new SerTimer(20);
                    node = Json.gobject_serialize(t);
                }
                t0 = (SerTimer)Json.gobject_deserialize(typeof(SerTimer), node);
            }
            Thread.usleep(30000);
            assert(t0.is_expired());
        }
        {
            SerTimer t0;
            {
                Json.Node node;
                {
                    SerTimer t = new SerTimer(20);
                    node = Json.gobject_serialize(t);
                }
                Thread.usleep(30000);
                t0 = (SerTimer)Json.gobject_deserialize(typeof(SerTimer), node);
            }
            assert(! t0.is_expired());
        }
    }

    public void test_coordkey()
    {
        CoordinatorKey k0;
        {
            Json.Node node;
            {
                CoordinatorKey k = new CoordinatorKey(2);
                node = Json.gobject_serialize(k);
            }
            k0 = (CoordinatorKey)Json.gobject_deserialize(typeof(CoordinatorKey), node);
        }
        assert(k0.lvl == 2);
    }

    public void test_booking()
    {
        Booking b0;
        {
            Json.Node node;
            {
                Booking b = new Booking();
                b.reserve_request_id = 1234;
                b.new_pos = 1;
                b.new_eldership = 3;
                b.timeout = new SerTimer(1);
                node = Json.gobject_serialize(b);
            }
            b0 = (Booking)Json.gobject_deserialize(typeof(Booking), node);
        }
        assert(b0.reserve_request_id == 1234);
        assert(b0.new_pos == 1);
        assert(b0.new_eldership == 3);
        assert(b0.timeout.is_expired());
    }

    public void test_memory()
    {
        {
            CoordGnodeMemory m0;
            {
                Json.Node node;
                {
                    CoordGnodeMemory m = new CoordGnodeMemory();

                    Booking b0 = new Booking();
                    b0.reserve_request_id = 1234;
                    b0.new_pos = 1;
                    b0.new_eldership = 4;
                    b0.timeout = new SerTimer(100);

                    Booking b1 = new Booking();
                    b1.reserve_request_id = 3245;
                    b1.new_pos = 2;
                    b1.new_eldership = 6;
                    b1.timeout = new SerTimer(2000);

                    Booking b2 = new Booking();
                    b2.reserve_request_id = 6666;
                    b2.new_pos = 3;
                    b2.new_eldership = 7;
                    b2.timeout = new SerTimer(3000);

                    m.reserve_list = new ArrayList<Booking>.wrap({b0, b1, b2});
                    m.max_virtual_pos = 121;
                    m.max_eldership = 7;
                    m.setnullable_n_nodes(2);
                    m.n_nodes_timeout = new SerTimer(4000);
                    print_object(m);
                    node = Json.gobject_serialize(m);
                }
                m0 = (CoordGnodeMemory)Json.gobject_deserialize(typeof(CoordGnodeMemory), node);
            }
        }
        {
            CoordGnodeMemory m0;
            {
                Json.Node node;
                {
                    CoordGnodeMemory m = new CoordGnodeMemory();

                    m.reserve_list = new ArrayList<Booking>();
                    m.max_virtual_pos = 121;
                    m.max_eldership = 7;
                    m.setnullable_n_nodes(null);
                    m.n_nodes_timeout = null;
                    print_object(m);
                    node = Json.gobject_serialize(m);
                }
                m0 = (CoordGnodeMemory)Json.gobject_deserialize(typeof(CoordGnodeMemory), node);
            }
        }
    }

/*
    internal class CoordGnodeMemory : Object
    {
        public Gee.List<Booking> reserve_list {get; set;}
        public int max_virtual_pos {get; set;}
        public int max_eldership {get; set;}
        public int? n_nodes {get; set;}
        public SerTimer? n_nodes_timeout {get; set;}
    }
*/

    public static int main(string[] args)
    {
        GLib.Test.init(ref args);
        GLib.Test.add_func ("/Serializables/SerTimer", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_timer();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/CoordinatorKey", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_coordkey();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/Booking", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_booking();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/CoordGnodeMemory", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_memory();
            x.tear_down();
        });
        GLib.Test.run();
        return 0;
    }
}

