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
using zcd;
using Netsukuku;

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
        Netsukuku.Timer t0;
        {
            Json.Node node;
            {
                Netsukuku.Timer t = new Netsukuku.Timer(30);
                debug(@"test_timer: start, ttl = $(t.msec_ttl)");
                Thread.usleep(10000);
                debug(@"test_timer: wait, ttl = $(t.msec_ttl)");
                assert(t.msec_ttl < 25);
                node = Json.gobject_serialize(t);
                debug(@"test_timer: serialized.");
                Thread.usleep(10000);
                debug(@"test_timer: wait.");
            }
            t0 = (Netsukuku.Timer)Json.gobject_deserialize(typeof(Netsukuku.Timer), node);
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

    public void test_request()
    {
        {
            CoordinatorRequest r0;
            {
                Json.Node node;
                {
                    CoordinatorRequest r = new CoordinatorRequest();
                    r.name = CoordinatorRequest.RESERVE;
                    r.reserve_lvl = 2;
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorRequest)Json.gobject_deserialize(typeof(CoordinatorRequest), node);
            }
            assert(r0.name == CoordinatorRequest.RESERVE);
            assert(r0.reserve_lvl == 2);
        }
        {
            CoordinatorRequest r0;
            {
                Json.Node node;
                {
                    CoordinatorRequest r = new CoordinatorRequest();
                    r.name = CoordinatorRequest.RETRIEVE_CACHE;
                    r.cache_from_lvl = 3;
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorRequest)Json.gobject_deserialize(typeof(CoordinatorRequest), node);
            }
            assert(r0.name == CoordinatorRequest.RETRIEVE_CACHE);
            assert(r0.cache_from_lvl == 3);
        }
        {
            CoordinatorRequest r0;
            {
                Json.Node node;
                {
                    CoordinatorRequest r = new CoordinatorRequest();
                    r.name = CoordinatorRequest.REPLICA_RESERVE;
                    r.replica_pos = 5;
                    r.replica_lvl = 2;
                    r.replica_eldership = 12;
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorRequest)Json.gobject_deserialize(typeof(CoordinatorRequest), node);
            }
            assert(r0.name == CoordinatorRequest.REPLICA_RESERVE);
            assert(r0.replica_pos == 5);
            assert(r0.replica_lvl == 2);
            assert(r0.replica_eldership == 12);
        }
    }

    public void test_reserve()
    {
        {
            CoordinatorReserveResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorReserveResponse r = new CoordinatorReserveResponse();
                    r.error_domain = "DeserializeError";
                    r.error_code = "GENERIC";
                    r.error_message = "Failed to read pos.";
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReserveResponse)Json.gobject_deserialize(typeof(CoordinatorReserveResponse), node);
            }
            assert(r0.error_domain == "DeserializeError");
            assert(r0.error_code == "GENERIC");
            assert(r0.error_message == "Failed to read pos.");
        }
        {
            CoordinatorReserveResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorReserveResponse r = new CoordinatorReserveResponse();
                    r.pos = 3;
                    r.elderships = new ArrayList<int>.wrap({12, 3, 5, 0, 0});
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReserveResponse)Json.gobject_deserialize(typeof(CoordinatorReserveResponse), node);
            }
            assert(r0.error_domain == null);
            assert(r0.error_code == null);
            assert(r0.error_message == null);
            assert(r0.pos == 3);
            assert(r0.elderships.size == 5);
            assert(r0.elderships[0] == 12);
            assert(r0.elderships[1] == 3);
            assert(r0.elderships[2] == 5);
            assert(r0.elderships[3] == 0);
            assert(r0.elderships[4] == 0);
        }
    }

    public void test_replica()
    {
        {
            CoordinatorReplicaReserveResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorReplicaReserveResponse r = new CoordinatorReplicaReserveResponse();
                    r.error_domain = "DeserializeError";
                    r.error_code = "GENERIC";
                    r.error_message = "Failed to read pos.";
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReplicaReserveResponse)Json.gobject_deserialize(typeof(CoordinatorReplicaReserveResponse), node);
            }
            assert(r0.error_domain == "DeserializeError");
            assert(r0.error_code == "GENERIC");
            assert(r0.error_message == "Failed to read pos.");
        }
        {
            CoordinatorReplicaReserveResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorReplicaReserveResponse r = new CoordinatorReplicaReserveResponse();
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorReplicaReserveResponse)Json.gobject_deserialize(typeof(CoordinatorReplicaReserveResponse), node);
            }
            assert(r0.error_domain == null);
            assert(r0.error_code == null);
            assert(r0.error_message == null);
        }
    }

    public void test_cache()
    {
        {
            CoordinatorRetrieveCacheResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorRetrieveCacheResponse r = new CoordinatorRetrieveCacheResponse();
                    r.error_domain = "DeserializeError";
                    r.error_code = "GENERIC";
                    r.error_message = "Failed to read pos.";
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorRetrieveCacheResponse)Json.gobject_deserialize(typeof(CoordinatorRetrieveCacheResponse), node);
            }
            assert(r0.error_domain == "DeserializeError");
            assert(r0.error_code == "GENERIC");
            assert(r0.error_message == "Failed to read pos.");
        }
        {
            CoordinatorRetrieveCacheResponse r0;
            {
                Json.Node node;
                {
                    CoordinatorRetrieveCacheResponse r = new CoordinatorRetrieveCacheResponse();
                    /* Asked for cache from lvl 3.
                     * At level 3 we have max_eldership 12. We do not have pending bookings.
                     * At level 4 we have max_eldership 3. We have a booking for position 4 that has 1 second to live,
                     *  and a booking for position 7 that has 34 msec to live.
                     */
                    r.max_eldership = new ArrayList<int>.wrap({12, 3});
                    r.bookings = new ArrayList<ArrayList<Booking>>.wrap(
                                    {
                                        new ArrayList<Booking>((a,b) => a.pos == b.pos),
                                        new ArrayList<Booking>.wrap(
                                            {
                                                new Booking(4, 1000),
                                                new Booking(7, 34)
                                            },
                                            (a,b) => a.pos == b.pos)
                                    });
                    node = Json.gobject_serialize(r);
                }
                r0 = (CoordinatorRetrieveCacheResponse)Json.gobject_deserialize(typeof(CoordinatorRetrieveCacheResponse), node);
            }
            assert(r0.error_domain == null);
            assert(r0.error_code == null);
            assert(r0.error_message == null);
            assert(r0.max_eldership.size == 2);
            assert(r0.max_eldership[0] == 12);
            assert(r0.max_eldership[1] == 3);
            assert(r0.bookings.size == 2);
            assert(r0.bookings[0].size == 0);
            assert(r0.bookings[1].size == 2);
            Booking b0 = r0.bookings[1][0];
            Booking b1 = r0.bookings[1][1];
            assert(b0.pos == 4);
            debug(@"test_cache: few less than 1000 = $(b0.ttl.msec_ttl)");
            assert(b1.pos == 7);
            debug(@"test_cache: few less than 34 = $(b1.ttl.msec_ttl)");
            // The list of bookings inside a certain level is searchable, on the basis of 'pos'.
            assert(r0.bookings[1].contains(new Booking(4, 99999)));
            assert(r0.bookings[1].contains(new Booking(7, 99999)));
            assert(!(r0.bookings[1].contains(new Booking(17, 99999))));
        }
    }

    public void test_reservation()
    {
        {
            Reservation r0;
            {
                Json.Node node;
                {
                    Reservation r = new Reservation(5, 3, {4, 2, 0});
                    node = Json.gobject_serialize(r);
                }
                r0 = (Reservation)Json.gobject_deserialize(typeof(Reservation), node);
            }
            assert(r0.check_deserialization());
            assert(r0.pos == 5);
            assert(r0.lvl == 3);
            assert(r0.eldership.size == 3);
            assert(r0.eldership[0] == 4);
            assert(r0.eldership[1] == 2);
            assert(r0.eldership[2] == 0);
        }
        {
            Reservation r0;
            {
                Json.Node node;
                {
                    Reservation r = new Reservation(0, 0, {});
                    node = Json.gobject_serialize(r);
                }
                r0 = (Reservation)Json.gobject_deserialize(typeof(Reservation), node);
            }
            assert(!r0.check_deserialization());
        }
    }

    public void test_neighbor_map()
    {
        {
            NeighborMap r0;
            {
                Json.Node node;
                {
                    NeighborMap r = new NeighborMap();
                    r.gsizes = new ArrayList<int>.wrap({2, 2, 2, 2, 2, 8});
                    r.free_pos = new ArrayList<int>.wrap({0, 0, 0, 0, 0, 0});
                    node = Json.gobject_serialize(r);
                }
                r0 = (NeighborMap)Json.gobject_deserialize(typeof(NeighborMap), node);
            }
            assert(r0.check_deserialization());
            assert(r0.gsizes.size == 6);
            assert(r0.gsizes[0] == 2);
            assert(r0.gsizes[5] == 8);
        }
        {
            NeighborMap r0;
            {
                Json.Node node;
                {
                    NeighborMap r = new NeighborMap();
                    r.gsizes = new ArrayList<int>.wrap({2, 2, 2, 2, 8});
                    r.free_pos = new ArrayList<int>.wrap({0, 0, 0, 0, 0, 0});
                    node = Json.gobject_serialize(r);
                }
                r0 = (NeighborMap)Json.gobject_deserialize(typeof(NeighborMap), node);
            }
            assert(!r0.check_deserialization());
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
        GLib.Test.add_func ("/Serializables/Request", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_request();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/ResponseReserve", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_reserve();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/ResponseReplica", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_replica();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/ResponseCache", () => {
            var x = new PeersTester();
            x.set_up();
            x.test_cache();
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

