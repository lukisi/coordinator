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

    public void test_tuple()
    {
        TupleGnode tg0;
        {
            Json.Node node;
            {
                TupleGnode tg = new TupleGnode();
                tg.tuple = new ArrayList<int>.wrap({1,2,3});
                node = Json.gobject_serialize(tg);
            }
            tg0 = (TupleGnode)Json.gobject_deserialize(typeof(TupleGnode), node);
        }
        assert(tg0.tuple.size == 3);
        assert(tg0.tuple[0] == 1);
        assert(tg0.tuple[1] == 2);
        assert(tg0.tuple[2] == 3);
    }

    public void test_object()
    {
        CoordinatorObject co0;
        {
                Json.Node node;
                {
                    CoordinatorObject co = new CoordinatorObject(make_sample_ser_object());
                    node = Json.gobject_serialize(co);
                }
                co0 = (CoordinatorObject)Json.gobject_deserialize(typeof(CoordinatorObject), node);
        }
        test_sample_ser_object(co0.object);
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
                b.timeout = new SerTimer(-1);
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
                    node = Json.gobject_serialize(m);
                }
                m0 = (CoordGnodeMemory)Json.gobject_deserialize(typeof(CoordGnodeMemory), node);
            }
        }
    }

    private CoordGnodeMemory make_sample_coordgnodememory()
    {
        CoordGnodeMemory m = new CoordGnodeMemory();
        m.reserve_list = new ArrayList<Booking>();
        m.max_virtual_pos = 121;
        m.max_eldership = 7;
        m.setnullable_n_nodes(null);
        m.n_nodes_timeout = null;
        return m;
    }

    private void test_sample_coordgnodememory(CoordGnodeMemory m)
    {
        assert(m.reserve_list.is_empty);
        assert(m.max_virtual_pos == 121);
        assert(m.max_eldership == 7);
        assert(m.getnullable_n_nodes() == null);
        assert(m.n_nodes_timeout == null);
    }

    private Object make_sample_ser_object()
    {
        return make_sample_coordgnodememory();
    }

    private void test_sample_ser_object(Object obj)
    {
        CoordGnodeMemory m = (CoordGnodeMemory)obj;
        test_sample_coordgnodememory(m);
    }

    public void test_requests()
    {
        NumberOfNodesRequest nnr0;
        {
            Json.Node node;
            {
                NumberOfNodesRequest nnr = new NumberOfNodesRequest();
                node = Json.gobject_serialize(nnr);
            }
            nnr0 = (NumberOfNodesRequest)Json.gobject_deserialize(typeof(NumberOfNodesRequest), node);
        }
        EvaluateEnterRequest eer0;
        {
            Json.Node node;
            {
                EvaluateEnterRequest eer = new EvaluateEnterRequest();
                eer.lvl = 1;
                eer.evaluate_enter_data = make_sample_ser_object();
                node = Json.gobject_serialize(eer);
            }
            eer0 = (EvaluateEnterRequest)Json.gobject_deserialize(typeof(EvaluateEnterRequest), node);
            assert(eer0.lvl == 1);
            test_sample_ser_object(eer0.evaluate_enter_data);
        }
        BeginEnterRequest ber0;
        {
            Json.Node node;
            {
                BeginEnterRequest ber = new BeginEnterRequest();
                ber.lvl = 1;
                ber.begin_enter_data = make_sample_ser_object();
                node = Json.gobject_serialize(ber);
            }
            ber0 = (BeginEnterRequest)Json.gobject_deserialize(typeof(BeginEnterRequest), node);
            assert(ber0.lvl == 1);
            test_sample_ser_object(ber0.begin_enter_data);
        }
        CompletedEnterRequest cer0;
        {
            Json.Node node;
            {
                CompletedEnterRequest cer = new CompletedEnterRequest();
                cer.lvl = 1;
                cer.completed_enter_data = make_sample_ser_object();
                node = Json.gobject_serialize(cer);
            }
            cer0 = (CompletedEnterRequest)Json.gobject_deserialize(typeof(CompletedEnterRequest), node);
            assert(cer0.lvl == 1);
            test_sample_ser_object(cer0.completed_enter_data);
        }
        AbortEnterRequest aer0;
        {
            Json.Node node;
            {
                AbortEnterRequest aer = new AbortEnterRequest();
                aer.lvl = 1;
                aer.abort_enter_data = make_sample_ser_object();
                node = Json.gobject_serialize(aer);
            }
            aer0 = (AbortEnterRequest)Json.gobject_deserialize(typeof(AbortEnterRequest), node);
            assert(aer0.lvl == 1);
            test_sample_ser_object(aer0.abort_enter_data);
        }
        GetHookingMemoryRequest ghmr0;
        {
            Json.Node node;
            {
                GetHookingMemoryRequest ghmr = new GetHookingMemoryRequest();
                ghmr.lvl = 1;
                node = Json.gobject_serialize(ghmr);
            }
            ghmr0 = (GetHookingMemoryRequest)Json.gobject_deserialize(typeof(GetHookingMemoryRequest), node);
            assert(ghmr0.lvl == 1);
        }
        SetHookingMemoryRequest shmr0;
        {
            Json.Node node;
            {
                SetHookingMemoryRequest shmr = new SetHookingMemoryRequest();
                shmr.lvl = 1;
                shmr.hooking_memory = make_sample_ser_object();
                node = Json.gobject_serialize(shmr);
            }
            shmr0 = (SetHookingMemoryRequest)Json.gobject_deserialize(typeof(SetHookingMemoryRequest), node);
            assert(shmr0.lvl == 1);
            test_sample_ser_object(shmr0.hooking_memory);
        }
        ReserveEnterRequest rer0;
        {
            Json.Node node;
            {
                ReserveEnterRequest rer = new ReserveEnterRequest();
                rer.lvl = 1;
                rer.reserve_request_id = 1234;
                node = Json.gobject_serialize(rer);
            }
            rer0 = (ReserveEnterRequest)Json.gobject_deserialize(typeof(ReserveEnterRequest), node);
            assert(rer0.lvl == 1);
            assert(rer0.reserve_request_id == 1234);
        }
        DeleteReserveEnterRequest drer0;
        {
            Json.Node node;
            {
                DeleteReserveEnterRequest drer = new DeleteReserveEnterRequest();
                drer.lvl = 1;
                drer.reserve_request_id = 1234;
                node = Json.gobject_serialize(drer);
            }
            drer0 = (DeleteReserveEnterRequest)Json.gobject_deserialize(typeof(DeleteReserveEnterRequest), node);
            assert(drer0.lvl == 1);
            assert(drer0.reserve_request_id == 1234);
        }
        ReplicaRequest rr0;
        {
            Json.Node node;
            {
                ReplicaRequest rr = new ReplicaRequest();
                rr.lvl = 1;
                rr.memory = make_sample_coordgnodememory();
                node = Json.gobject_serialize(rr);
            }
            rr0 = (ReplicaRequest)Json.gobject_deserialize(typeof(ReplicaRequest), node);
            assert(rr0.lvl == 1);
            test_sample_coordgnodememory(rr0.memory);
        }
    }

    public void test_responses()
    {
        NumberOfNodesResponse nnr0;
        {
            Json.Node node;
            {
                NumberOfNodesResponse nnr = new NumberOfNodesResponse();
                nnr.n_nodes = 1;
                node = Json.gobject_serialize(nnr);
            }
            nnr0 = (NumberOfNodesResponse)Json.gobject_deserialize(typeof(NumberOfNodesResponse), node);
            assert(nnr0.n_nodes == 1);
        }
        EvaluateEnterResponse eer0;
        {
            Json.Node node;
            {
                EvaluateEnterResponse eer = new EvaluateEnterResponse();
                eer.evaluate_enter_result = make_sample_ser_object();
                node = Json.gobject_serialize(eer);
            }
            eer0 = (EvaluateEnterResponse)Json.gobject_deserialize(typeof(EvaluateEnterResponse), node);
            test_sample_ser_object(eer0.evaluate_enter_result);
        }
        BeginEnterResponse ber0;
        {
            Json.Node node;
            {
                BeginEnterResponse ber = new BeginEnterResponse();
                ber.begin_enter_result = make_sample_ser_object();
                node = Json.gobject_serialize(ber);
            }
            ber0 = (BeginEnterResponse)Json.gobject_deserialize(typeof(BeginEnterResponse), node);
            test_sample_ser_object(ber0.begin_enter_result);
        }
        CompletedEnterResponse cer0;
        {
            Json.Node node;
            {
                CompletedEnterResponse cer = new CompletedEnterResponse();
                cer.completed_enter_result = make_sample_ser_object();
                node = Json.gobject_serialize(cer);
            }
            cer0 = (CompletedEnterResponse)Json.gobject_deserialize(typeof(CompletedEnterResponse), node);
            test_sample_ser_object(cer0.completed_enter_result);
        }
        AbortEnterResponse aer0;
        {
            Json.Node node;
            {
                AbortEnterResponse aer = new AbortEnterResponse();
                aer.abort_enter_result = make_sample_ser_object();
                node = Json.gobject_serialize(aer);
            }
            aer0 = (AbortEnterResponse)Json.gobject_deserialize(typeof(AbortEnterResponse), node);
            test_sample_ser_object(aer0.abort_enter_result);
        }
        GetHookingMemoryResponse ghmr0;
        {
            Json.Node node;
            {
                GetHookingMemoryResponse ghmr = new GetHookingMemoryResponse();
                ghmr.hooking_memory = make_sample_ser_object();
                node = Json.gobject_serialize(ghmr);
            }
            ghmr0 = (GetHookingMemoryResponse)Json.gobject_deserialize(typeof(GetHookingMemoryResponse), node);
            test_sample_ser_object(ghmr0.hooking_memory);
        }
        SetHookingMemoryResponse shmr0;
        {
            Json.Node node;
            {
                SetHookingMemoryResponse shmr = new SetHookingMemoryResponse();
                node = Json.gobject_serialize(shmr);
            }
            shmr0 = (SetHookingMemoryResponse)Json.gobject_deserialize(typeof(SetHookingMemoryResponse), node);
        }
        ReserveEnterResponse rer0;
        {
            Json.Node node;
            {
                ReserveEnterResponse rer = new ReserveEnterResponse();
                rer.new_pos = 1;
                rer.new_eldership = 2;
                node = Json.gobject_serialize(rer);
            }
            rer0 = (ReserveEnterResponse)Json.gobject_deserialize(typeof(ReserveEnterResponse), node);
            assert(rer0.new_pos == 1);
            assert(rer0.new_eldership == 2);
        }
        DeleteReserveEnterResponse drer0;
        {
            Json.Node node;
            {
                DeleteReserveEnterResponse drer = new DeleteReserveEnterResponse();
                node = Json.gobject_serialize(drer);
            }
            drer0 = (DeleteReserveEnterResponse)Json.gobject_deserialize(typeof(DeleteReserveEnterResponse), node);
        }
        ReplicaResponse rr0;
        {
            Json.Node node;
            {
                ReplicaResponse rr = new ReplicaResponse();
                node = Json.gobject_serialize(rr);
            }
            rr0 = (ReplicaResponse)Json.gobject_deserialize(typeof(ReplicaResponse), node);
        }
    }

    public static int main(string[] args)
    {
        GLib.Test.init(ref args);
        GLib.Test.add_func ("/Serializables/TupleGnode", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_tuple();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/CoordinatorObject", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_object();
            x.tear_down();
        });
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
        GLib.Test.add_func ("/Serializables/Requests", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_requests();
            x.tear_down();
        });
        GLib.Test.add_func ("/Serializables/Responses", () => {
            var x = new CoordTester();
            x.set_up();
            x.test_responses();
            x.tear_down();
        });
        GLib.Test.run();
        return 0;
    }
}

