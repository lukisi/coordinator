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
using Netsukuku.PeerServices;
using TaskletSystem;

namespace Netsukuku.Coordinator
{
    internal class CoordDatabaseDescriptor : Object, IDatabaseDescriptor, IFixedKeysDatabaseDescriptor
    {
        private CoordService service;
        private CoordinatorManager mgr;
        public CoordDatabaseDescriptor(CoordService service)
        {
            this.service = service;
            this.mgr = service.mgr;
        }

        private DatabaseHandler _dh;

        public unowned DatabaseHandler dh_getter()
        {
            return _dh;
        }

        public void dh_setter(DatabaseHandler x)
        {
            _dh = x;
        }

        public bool is_valid_key(Object k)
        {
            if (k is CoordinatorKey)
            {
                int lvl = ((CoordinatorKey)k).lvl;
                if (lvl >= 1 && lvl <= mgr.levels) return true;
            }
            return false;
        }

        public Gee.List<int> evaluate_hash_node(Object k)
        {
            assert(k is CoordinatorKey);
            return service.client.perfect_tuple(k);
        }

        public bool key_equal_data(Object k1, Object k2)
        {
            assert(k1 is CoordinatorKey);
            CoordinatorKey _k1 = (CoordinatorKey)k1;
            assert(k2 is CoordinatorKey);
            CoordinatorKey _k2 = (CoordinatorKey)k2;
            return CoordinatorKey.equal_data(_k1, _k2);
        }

        public uint key_hash_data(Object k)
        {
            assert(k is CoordinatorKey);
            CoordinatorKey _k = (CoordinatorKey)k;
            return CoordinatorKey.hash_data(_k);
        }

        public bool is_valid_record(Object k, Object rec)
        {
            if (! is_valid_key(k)) return false;
            if (! (rec is CoordGnodeMemory)) return false;
            return true;
        }

        public bool my_records_contains(Object k)
        {
            return true;
        }

        public Object get_record_for_key(Object k)
        {
            assert(k is CoordinatorKey);
            CoordinatorKey _k = (CoordinatorKey)k;
            assert(is_valid_key(k));
            int lvl = _k.lvl;
            return service.my_memory[lvl];
        }

        public void set_record_for_key(Object k, Object rec)
        {
            assert(k is CoordinatorKey);
            CoordinatorKey _k = (CoordinatorKey)k;
            assert(is_valid_key(k));
            int lvl = _k.lvl;
            if (! is_valid_record(k, rec))
            {
                // Invalid request. Terminate the tasklet handling this request.
                warning(@"CoordDatabaseDescriptor: set_record_for_key: Got invalid record class: $(rec.get_type().name())");
                tasklet.exit_tasklet();
            }
            CoordGnodeMemory _rec = (CoordGnodeMemory)rec;
            service.my_memory[lvl] = _rec;
        }

        public Object get_key_from_request(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                return new CoordinatorKey(mgr.levels);
            } else if (r is EvaluateEnterRequest) {
                EvaluateEnterRequest _r = (EvaluateEnterRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is BeginEnterRequest) {
                BeginEnterRequest _r = (BeginEnterRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is CompletedEnterRequest) {
                CompletedEnterRequest _r = (CompletedEnterRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is AbortEnterRequest) {
                AbortEnterRequest _r = (AbortEnterRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is GetHookingMemoryRequest) {
                GetHookingMemoryRequest _r = (GetHookingMemoryRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is SetHookingMemoryRequest) {
                SetHookingMemoryRequest _r = (SetHookingMemoryRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is ReserveEnterRequest) {
                ReserveEnterRequest _r = (ReserveEnterRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is DeleteReserveEnterRequest) {
                DeleteReserveEnterRequest _r = (DeleteReserveEnterRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else if (r is ReplicaRequest) {
                ReplicaRequest _r = (ReplicaRequest)r;
                return new CoordinatorKey(_r.lvl);
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public int get_timeout_exec(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                return timeout_exec_for_request(r);
            } else if (r is EvaluateEnterRequest) {
                warning(@"Unexpected to call fkdd.get_timeout_exec for class $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is BeginEnterRequest) {
                warning(@"Unexpected to call fkdd.get_timeout_exec for class $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is CompletedEnterRequest) {
                warning(@"Unexpected to call fkdd.get_timeout_exec for class $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is AbortEnterRequest) {
                warning(@"Unexpected to call fkdd.get_timeout_exec for class $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is GetHookingMemoryRequest) {
                warning(@"Unexpected to call fkdd.get_timeout_exec for class $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is SetHookingMemoryRequest) {
                return timeout_exec_for_request(r);
            } else if (r is ReserveEnterRequest) {
                return timeout_exec_for_request(r);
            } else if (r is DeleteReserveEnterRequest) {
                return timeout_exec_for_request(r);
            } else if (r is ReplicaRequest) {
                error("not implemented yet");
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public bool is_insert_request(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                return false;
            } else if (r is EvaluateEnterRequest) {
                return false;
            } else if (r is BeginEnterRequest) {
                return false;
            } else if (r is CompletedEnterRequest) {
                return false;
            } else if (r is AbortEnterRequest) {
                return false;
            } else if (r is GetHookingMemoryRequest) {
                return false;
            } else if (r is SetHookingMemoryRequest) {
                return false;
            } else if (r is ReserveEnterRequest) {
                return false;
            } else if (r is DeleteReserveEnterRequest) {
                return false;
            } else if (r is ReplicaRequest) {
                return false;
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public bool is_read_only_request(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                return false;
            } else if (r is EvaluateEnterRequest) {
                return false;
            } else if (r is BeginEnterRequest) {
                return false;
            } else if (r is CompletedEnterRequest) {
                return false;
            } else if (r is AbortEnterRequest) {
                return false;
            } else if (r is GetHookingMemoryRequest) {
                return true;
            } else if (r is SetHookingMemoryRequest) {
                return false;
            } else if (r is ReserveEnterRequest) {
                return false;
            } else if (r is DeleteReserveEnterRequest) {
                return false;
            } else if (r is ReplicaRequest) {
                return false;
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public bool is_update_request(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                return true;
            } else if (r is EvaluateEnterRequest) {
                return false;
            } else if (r is BeginEnterRequest) {
                return false;
            } else if (r is CompletedEnterRequest) {
                return false;
            } else if (r is AbortEnterRequest) {
                return false;
            } else if (r is GetHookingMemoryRequest) {
                return false;
            } else if (r is SetHookingMemoryRequest) {
                return true;
            } else if (r is ReserveEnterRequest) {
                return true;
            } else if (r is DeleteReserveEnterRequest) {
                return true;
            } else if (r is ReplicaRequest) {
                return false;
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public bool is_replica_value_request(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                return false;
            } else if (r is EvaluateEnterRequest) {
                return false;
            } else if (r is BeginEnterRequest) {
                return false;
            } else if (r is CompletedEnterRequest) {
                return false;
            } else if (r is AbortEnterRequest) {
                return false;
            } else if (r is GetHookingMemoryRequest) {
                return false;
            } else if (r is SetHookingMemoryRequest) {
                return false;
            } else if (r is ReserveEnterRequest) {
                return false;
            } else if (r is DeleteReserveEnterRequest) {
                return false;
            } else if (r is ReplicaRequest) {
                return true;
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public bool is_replica_delete_request(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                return false;
            } else if (r is EvaluateEnterRequest) {
                return false;
            } else if (r is BeginEnterRequest) {
                return false;
            } else if (r is CompletedEnterRequest) {
                return false;
            } else if (r is AbortEnterRequest) {
                return false;
            } else if (r is GetHookingMemoryRequest) {
                return false;
            } else if (r is SetHookingMemoryRequest) {
                return false;
            } else if (r is ReserveEnterRequest) {
                return false;
            } else if (r is DeleteReserveEnterRequest) {
                return false;
            } else if (r is ReplicaRequest) {
                return false;
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public IPeersResponse prepare_response_not_found(IPeersRequest r)
        {
            if (r is NumberOfNodesRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is EvaluateEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is BeginEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is CompletedEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is AbortEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is GetHookingMemoryRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is SetHookingMemoryRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is ReserveEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is DeleteReserveEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is ReplicaRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_found: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public IPeersResponse prepare_response_not_free(IPeersRequest r, Object rec)
        {
            if (r is NumberOfNodesRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is EvaluateEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is BeginEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is CompletedEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is AbortEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is GetHookingMemoryRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is SetHookingMemoryRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is ReserveEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is DeleteReserveEnterRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else if (r is ReplicaRequest) {
                // No such response expected for this request.
                warning(@"CoordDatabaseDescriptor: prepare_response_not_free: Unexpected for class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public IPeersResponse execute(IPeersRequest r, Gee.List<int> client_tuple) throws PeersRefuseExecutionError, PeersRedoFromStartError
        {
            if (r is NumberOfNodesRequest) {
                CoordinatorKey k = (CoordinatorKey)get_key_from_request(r);
                CoordGnodeMemory mem = (CoordGnodeMemory)get_record_for_key(k);
                NumberOfNodesResponse resp = new NumberOfNodesResponse();
                if (mem.n_nodes_timeout != null && ! mem.n_nodes_timeout.is_expired() && mem.getnullable_n_nodes() != null)
                {
                    resp.n_nodes = (int)mem.getnullable_n_nodes();
                }
                else
                {
                    resp.n_nodes = mgr.map.get_n_nodes();
                }
                mem.n_nodes_timeout = new SerTimer(CoordService.msec_n_nodes);
                mem.setnullable_n_nodes(resp.n_nodes);
                set_record_for_key(k, mem);
                // Launch tasklet for replicas
                request_all_replicas_in_tasklet(k, mem);
                return resp;
            } else if (r is EvaluateEnterRequest) {
                EvaluateEnterRequest _r = (EvaluateEnterRequest)r;
                EvaluateEnterResponse ret = new EvaluateEnterResponse();
                try {
                    ret.evaluate_enter_result =
                        mgr.evaluate_enter_handler.evaluate_enter(_r.lvl, _r.evaluate_enter_data);
                } catch (HandlingImpossibleError e) {
                    tasklet.exit_tasklet();
                }
                return ret;
            } else if (r is BeginEnterRequest) {
                BeginEnterRequest _r = (BeginEnterRequest)r;
                BeginEnterResponse ret = new BeginEnterResponse();
                try {
                    ret.begin_enter_result =
                        mgr.begin_enter_handler.begin_enter(_r.lvl, _r.begin_enter_data);
                } catch (HandlingImpossibleError e) {
                    tasklet.exit_tasklet();
                }
                return ret;
            } else if (r is CompletedEnterRequest) {
                CompletedEnterRequest _r = (CompletedEnterRequest)r;
                CompletedEnterResponse ret = new CompletedEnterResponse();
                try {
                    ret.completed_enter_result =
                        mgr.completed_enter_handler.completed_enter(_r.lvl, _r.completed_enter_data);
                } catch (HandlingImpossibleError e) {
                    tasklet.exit_tasklet();
                }
                return ret;
            } else if (r is AbortEnterRequest) {
                AbortEnterRequest _r = (AbortEnterRequest)r;
                AbortEnterResponse ret = new AbortEnterResponse();
                try {
                    ret.abort_enter_result =
                        mgr.abort_enter_handler.abort_enter(_r.lvl, _r.abort_enter_data);
                } catch (HandlingImpossibleError e) {
                    tasklet.exit_tasklet();
                }
                return ret;
            } else if (r is GetHookingMemoryRequest) {
                CoordinatorKey k = (CoordinatorKey)get_key_from_request(r);
                CoordGnodeMemory mem = (CoordGnodeMemory)get_record_for_key(k);
                GetHookingMemoryResponse resp = new GetHookingMemoryResponse();
                resp.hooking_memory = mem.hooking_memory;
                return resp;
            } else if (r is SetHookingMemoryRequest) {
                if (! client_tuple.is_empty)
                {
                    // Not the right dude to ask
                    warning("CoordService: execute SetHookingMemoryRequest: I am not the Coordinator.");
                    tasklet.exit_tasklet();
                }
                CoordinatorKey k = (CoordinatorKey)get_key_from_request(r);
                CoordGnodeMemory mem = (CoordGnodeMemory)get_record_for_key(k);
                SetHookingMemoryRequest _r = (SetHookingMemoryRequest)r;
                mem.hooking_memory = _r.hooking_memory;
                set_record_for_key(k, mem);
                // Launch tasklet for replicas
                request_all_replicas_in_tasklet(k, mem);
                return new SetHookingMemoryResponse();
            } else if (r is ReserveEnterRequest) {
                int lvl = ((ReserveEnterRequest)r).lvl;
                int reserve_request_id = ((ReserveEnterRequest)r).reserve_request_id;
                CoordinatorKey k = (CoordinatorKey)get_key_from_request(r);
                CoordGnodeMemory mem = (CoordGnodeMemory)get_record_for_key(k);
                // remove expired bookings
                int i = 0;
                while (mem.reserve_list.size > i)
                {
                    Booking b = mem.reserve_list[i];
                    if (b.timeout.is_expired())
                    {
                        mem.reserve_list.remove_at(i);
                    }
                    else
                    {
                        i++;
                    }
                }
                // prepare result data
                int new_pos = -1;
                int new_eldership = -1;
                // check if this request was already served.
                bool r_already_served = false;
                foreach (Booking b in mem.reserve_list) if (b.reserve_request_id == reserve_request_id)
                {
                    new_pos = b.new_pos;
                    new_eldership = b.new_eldership;
                    r_already_served = true;
                    b.timeout = new SerTimer(CoordService.msec_new_reservation);
                    break;
                }
                if (! r_already_served)
                {
                    // reserve free pos
                    foreach (int p in mgr.map.get_free_pos(lvl-1))
                    {
                        // is `p` already served?
                        bool p_already_served = false;
                        foreach (Booking b in mem.reserve_list) if (b.new_pos == p)
                        {
                            p_already_served = true;
                            break;
                        }
                        if (p_already_served) continue;
                        // go on with this p.
                        new_pos = p;
                        break;
                    }
                    if (new_pos == -1)
                    {
                        // virtual
                        new_pos = ++mem.max_virtual_pos;
                    }
                    new_eldership = ++mem.max_eldership;
                    Booking new_b = new Booking();
                    new_b.reserve_request_id = reserve_request_id;
                    new_b.new_pos = new_pos;
                    new_b.new_eldership = new_eldership;
                    new_b.timeout = new SerTimer(CoordService.msec_new_reservation);
                    mem.reserve_list.add(new_b);
                }
                // Launch tasklet for replicas
                request_all_replicas_in_tasklet(k, mem);
                // return resp
                ReserveEnterResponse resp = new ReserveEnterResponse();
                resp.new_pos = new_pos;
                resp.new_eldership = new_eldership;
                return resp;
            } else if (r is DeleteReserveEnterRequest) {
                int reserve_request_id = ((DeleteReserveEnterRequest)r).reserve_request_id;
                CoordinatorKey k = (CoordinatorKey)get_key_from_request(r);
                CoordGnodeMemory mem = (CoordGnodeMemory)get_record_for_key(k);
                // look for this request and remove it.
                int i = 0;
                while (mem.reserve_list.size > i)
                {
                    Booking b = mem.reserve_list[i];
                    if (b.reserve_request_id == reserve_request_id)
                    {
                        mem.reserve_list.remove_at(i);
                        break;
                    }
                    else
                    {
                        i++;
                    }
                }
                set_record_for_key(k, mem);
                // Launch tasklet for replicas
                request_all_replicas_in_tasklet(k, mem);
                return new DeleteReserveEnterResponse();
            } else if (r is ReplicaRequest) {
                error("not implemented yet");
            } else {
                // Unknown request. Terminate the tasklet handling this request.
                warning(@"Got unknown request class: $(r.get_type().name())");
                tasklet.exit_tasklet();
            }
        }

        public Gee.List<Object> get_full_key_domain()
        {
            var ret = new ArrayList<Object>();
            for (int i = 1; i <= mgr.levels; i++) ret.add(new CoordinatorKey(i));
            return ret;
        }

        public Object get_default_record_for_key(Object k)
        {
            assert(k is CoordinatorKey);
            CoordinatorKey _k = (CoordinatorKey)k;
            assert(is_valid_key(k));
            int lvl = _k.lvl;
            return service.new_coordgnodememory(lvl);
        }

        private bool request_first_replica(CoordinatorKey k, CoordGnodeMemory record, out IReplicaContinuation cont)
        {
            Gee.List<int> perfect_tuple = service.client.perfect_tuple(k);
            ReplicaRequest r = new ReplicaRequest();
            r.lvl = k.lvl;
            r.memory = record;
            int timeout_exec = timeout_exec_for_request(r);
            IPeersResponse resp;
            bool ret = service.peers_manager.begin_replica
                (CoordService.q_replica_new_reservation, CoordService.coordinator_p_id,
                 perfect_tuple, r, timeout_exec, out resp, out cont);
            if (ret)
            {
                if (resp == null)
                    warning("CoordDatabaseDescriptor: sending replica: returned null");
                else if (! (resp is ReplicaResponse))
                    warning(@"CoordDatabaseDescriptor: sending replica: returned unknown class $(resp.get_type().name())");
            }
            return ret;
        }
        private bool request_next_replica(IReplicaContinuation cont)
        {
            IPeersResponse resp;
            bool ret = service.peers_manager.next_replica(cont, out resp);
            if (ret)
            {
                if (resp == null)
                    warning("CoordDatabaseDescriptor: sending replica: returned null");
                else if (! (resp is ReplicaResponse))
                    warning(@"CoordDatabaseDescriptor: sending replica: returned unknown class $(resp.get_type().name())");
            }
            return ret;
        }
        private void request_finish_replicas_in_tasklet(IReplicaContinuation cont)
        {
            RequestFinishReplicasTasklet ts = new RequestFinishReplicasTasklet();
            ts.t = this;
            ts.cont = cont;
            tasklet.spawn(ts);
        }
        private class RequestFinishReplicasTasklet : Object, ITaskletSpawnable
        {
            public CoordDatabaseDescriptor t;
            public IReplicaContinuation cont;
            public void * func()
            {
                t.tasklet_request_finish_replicas(cont);
                return null;
            }
        }
        private void tasklet_request_finish_replicas(IReplicaContinuation cont)
        {
            IPeersResponse resp;
            while (service.peers_manager.next_replica(cont, out resp))
            {
                if (resp == null)
                    warning("CoordDatabaseDescriptor: sending replica: returned null");
                else if (! (resp is ReplicaResponse))
                    warning(@"CoordDatabaseDescriptor: sending replica: returned unknown class $(resp.get_type().name())");
                // nop
            }
        }

        private void request_all_replicas_in_tasklet(CoordinatorKey k, CoordGnodeMemory record)
        {
            RequestAllReplicasTasklet ts = new RequestAllReplicasTasklet();
            ts.t = this;
            ts.k = k;
            ts.record = record;
            tasklet.spawn(ts);
        }
        private class RequestAllReplicasTasklet : Object, ITaskletSpawnable
        {
            public CoordDatabaseDescriptor t;
            public CoordinatorKey k;
            public CoordGnodeMemory record;
            public void * func()
            {
                t.tasklet_request_all_replicas(k, record);
                return null;
            }
        }
        private void tasklet_request_all_replicas(CoordinatorKey k, CoordGnodeMemory record)
        {
            IReplicaContinuation cont;
            bool ret = request_first_replica(k, record, out cont);
            while (ret)
            {
                ret = request_next_replica(cont);
            }
        }
    }
}
