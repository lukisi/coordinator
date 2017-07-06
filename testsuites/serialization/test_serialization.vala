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

using Gee;
using Netsukuku;
using Netsukuku.Coordinator;
using TaskletSystem;

class PeersTester : Object
{
    public void set_up ()
    {
    }

    public void tear_down ()
    {
    }

    public void test_timer()
    {
        Netsukuku.Coordinator.Timer t0;
        {
            Json.Node node;
            {
                Netsukuku.Coordinator.Timer t = new Netsukuku.Coordinator.Timer(30);
                debug(@"test_timer: start, ttl = $(t.msec_ttl)");
                Thread.usleep(10000);
                debug(@"test_timer: wait, ttl = $(t.msec_ttl)");
                assert(t.msec_ttl < 25);
                node = Json.gobject_serialize(t);
                debug(@"test_timer: serialized.");
                Thread.usleep(10000);
                debug(@"test_timer: wait.");
            }
            t0 = (Netsukuku.Coordinator.Timer)Json.gobject_deserialize(typeof(Netsukuku.Coordinator.Timer), node);
            debug(@"test_timer: deserialized.");
        }
        debug(@"test_timer: ttl = $(t0.msec_ttl)");
        assert(t0.msec_ttl > 15);
        Thread.usleep(25000);
        assert(t0.is_expired());
    }

    public void test_booking()
    {
        Booking b0;
        {
            Json.Node node;
            {
                Booking b = new Booking(2, 30);
                debug(@"test_booking: start, ttl = $(b.ttl.msec_ttl)");
                Thread.usleep(10000);
                debug(@"test_booking: wait, ttl = $(b.ttl.msec_ttl)");
                assert(b.ttl.msec_ttl < 25);
                node = Json.gobject_serialize(b);
                debug(@"test_booking: serialized.");
                Thread.usleep(10000);
                debug(@"test_booking: wait.");
            }
            b0 = (Booking)Json.gobject_deserialize(typeof(Booking), node);
            debug(@"test_booking: deserialized.");
        }
        debug(@"test_booking: ttl = $(b0.ttl.msec_ttl)");
        assert(b0.ttl.msec_ttl > 15);
        Thread.usleep(25000);
        assert(b0.ttl.is_expired());
    }

    public void test_key()
    {
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
    }

    public void test_record()
    {
        {
            CoordinatorRecord r0;
            {
                Json.Node node;
                {
                    ArrayList<Booking> booking_list = new ArrayList<Booking>((a,b) => a.pos == b.pos);
                    booking_list.add(new Booking(2, 20000));
                    booking_list.add(new Booking(3, 20000));
                    CoordinatorRecord r = new CoordinatorRecord(2, booking_list, 3);
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorRecord)Json.gobject_deserialize(typeof(CoordinatorRecord), node);
            }
            assert(r0.lvl == 2);
            assert(! r0.booking_list.contains(new Booking(1, 12345)));
            assert(r0.booking_list.contains(new Booking(2, 12345)));
            assert(r0.booking_list.contains(new Booking(3, 12345)));
            assert(r0.max_eldership == 3);
        }
    }

    public void test_reserve_request()
    {
        {
            CoordinatorReserveRequest r0;
            {
                Json.Node node;
                {
                    CoordinatorReserveRequest r = new CoordinatorReserveRequest(2);
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReserveRequest)Json.gobject_deserialize(typeof(CoordinatorReserveRequest), node);
            }
            assert(r0.lvl == 2);
        }
    }

    public void test_reserve_response()
    {
        {
            CoordinatorReserveResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorReserveResponse r = new CoordinatorReserveResponse.error("a", "b", "c");
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReserveResponse)Json.gobject_deserialize(typeof(CoordinatorReserveResponse), node);
            }
            assert(r0.error_domain == "a");
            assert(r0.error_code == "b");
            assert(r0.error_message == "c");
        }
        {
            CoordinatorReserveResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorReserveResponse r = new CoordinatorReserveResponse.success(2, 3);
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReserveResponse)Json.gobject_deserialize(typeof(CoordinatorReserveResponse), node);
            }
            assert(r0.error_domain == null);
            assert(r0.error_code == null);
            assert(r0.error_message == null);
            assert(r0.pos == 2);
            assert(r0.eldership == 3);
        }
    }

    public void test_replica()
    {
        {
            CoordinatorReplicaRecordRequest r0;
            {
                Json.Node node;
                {
                    ArrayList<Booking> booking_list = new ArrayList<Booking>((a,b) => a.pos == b.pos);
                    booking_list.add(new Booking(2, 20000));
                    booking_list.add(new Booking(3, 20000));
                    CoordinatorRecord rec = new CoordinatorRecord(2, booking_list, 3);
                    CoordinatorReplicaRecordRequest r = new CoordinatorReplicaRecordRequest(rec);
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReplicaRecordRequest)Json.gobject_deserialize(typeof(CoordinatorReplicaRecordRequest), node);
            }
            assert(r0.record.lvl == 2);
            assert(! r0.record.booking_list.contains(new Booking(1, 12345)));
            assert(r0.record.booking_list.contains(new Booking(2, 12345)));
            assert(r0.record.booking_list.contains(new Booking(3, 12345)));
            assert(r0.record.max_eldership == 3);
        }
    }

    public void test_reservation()
    {
        {
            Reservation r0;
            {
                Json.Node node;
                {
                    ArrayList<int> gsizes = new ArrayList<int>();
                    gsizes.add(2);
                    gsizes.add(2);
                    gsizes.add(2);
                    gsizes.add(2);
                    ArrayList<int> upper_pos = new ArrayList<int>();
                    upper_pos.add(0);
                    ArrayList<int> upper_elderships = new ArrayList<int>();
                    upper_elderships.add(5);
                    Reservation r = new Reservation(4, gsizes,
                            2, 1, 20,
                            upper_pos, upper_elderships);
                    node = Json.gobject_serialize(r);
                }
                r0 = (Reservation)Json.gobject_deserialize(typeof(Reservation), node);
            }
            assert(r0.check_deserialization());
            assert(r0.levels == 4);
            assert(r0.gsizes[0] == 2);
            assert(r0.gsizes[1] == 2);
            assert(r0.gsizes[2] == 2);
            assert(r0.gsizes[3] == 2);
            assert(r0.lvl == 2);
            assert(r0.pos == 1);
            assert(r0.eldership == 20);
            assert(r0.upper_pos.size == 1);
            assert(r0.upper_pos[0] == 0);
            assert(r0.upper_elderships.size == 1);
            assert(r0.upper_elderships[0] == 5);
        }
    }

    public void test_neighbor_map()
    {
        {
            NeighborMap r0;
            {
                Json.Node node;
                {
                    NeighborMap r = new NeighborMap(
                        new ArrayList<int>.wrap({2, 2, 2, 2, 2, 8}),
                        new ArrayList<int>.wrap({0, 0, 0, 0, 0, 3}));
                    node = Json.gobject_serialize(r);
                }
                r0 = (NeighborMap)Json.gobject_deserialize(typeof(NeighborMap), node);
            }
            assert(r0.check_deserialization());
            assert(r0.gsizes.size == 6);
            assert(r0.gsizes[0] == 2);
            assert(r0.gsizes[5] == 8);
            assert(r0.free_pos_count_list[5] == 3);
        }
    }

    public static int main(string[] args)
    {
        GLib.Test.init(ref args);
        GLib.Test.add_func ("/Serializables/Timer", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_timer();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/Booking", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_booking();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/Key", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_key();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/Record", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_record();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/ReserveRequest", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_reserve_request();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/ReserveResponse", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_reserve_response();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/Replica", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_replica();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/Reservation", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_reservation();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/NeighborMap", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_neighbor_map();
            x.tear_down();
        });
        GLib.Test.run();
        return 0;
    }
}

