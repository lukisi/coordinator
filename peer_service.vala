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
using Netsukuku.PeerServices;
using TaskletSystem;

namespace Netsukuku.Coordinator
{
    internal class CoordService : PeerService
    {
        internal const int coordinator_p_id = 1;
        internal const int msec_new_reservation = 60000; // for new Booking
        internal const int msec_n_nodes = 20000; // for answers to get_n_nodes
        internal const int q_replica_new_reservation = 15; // for replicas

        internal PeersManager peers_manager;
        internal CoordinatorManager mgr;
        internal CoordDatabaseDescriptor fkdd;
        internal CoordClient client;

        internal HashMap<int, CoordGnodeMemory> my_memory;

        public CoordService(PeersManager peers_manager, CoordinatorManager mgr, CoordService? prev_service)
        {
            base(coordinator_p_id, false);
            this.peers_manager = peers_manager;
            this.mgr = mgr;
            fkdd = new CoordDatabaseDescriptor(this);
            client = new CoordClient(mgr.gsizes, peers_manager, mgr);
            my_memory = new HashMap<int, CoordGnodeMemory>();
            for (int i = 1; i <= mgr.levels; i++) my_memory[i] = new_coordgnodememory(i);
 
            peers_manager.register(this);
            // launch fixed_keys_db_on_startup in a tasklet
            StartFixedKeysDbHandlerTasklet ts = new StartFixedKeysDbHandlerTasklet();
            ts.t = this;
            ts.prev_service = prev_service;
            tasklet.spawn(ts);
        }
        private class StartFixedKeysDbHandlerTasklet : Object, ITaskletSpawnable
        {
            public CoordService t;
            public CoordService? prev_service;
            public void * func()
            {
                t.tasklet_start_fixed_keys_db_handler(prev_service);
                return null;
            }
        }
        private void tasklet_start_fixed_keys_db_handler(CoordService? prev_service)
        {
            IFixedKeysDatabaseDescriptor? prev_fkdd = null;
            if (prev_service != null) prev_fkdd = prev_service.fkdd;
            peers_manager.fixed_keys_db_on_startup
                (fkdd, coordinator_p_id, prev_fkdd);
        }

        public override IPeersResponse exec(IPeersRequest req, Gee.List<int> client_tuple) throws PeersRefuseExecutionError, PeersRedoFromStartError
        {
            return peers_manager.fixed_keys_db_on_request(fkdd, req, client_tuple);
        }

        internal CoordGnodeMemory new_coordgnodememory(int lvl)
        {
            CoordGnodeMemory ret = new CoordGnodeMemory();
            ret.reserve_list = new ArrayList<Booking>();
            ret.max_virtual_pos = mgr.gsizes[lvl-1];
            ret.max_eldership = 0;
            ret.setnullable_n_nodes(null);
            ret.n_nodes_timeout = null;
            return ret;
        }

        // ...
    }

    internal int timeout_exec_for_request(IPeersRequest r)
    {
        int timeout_write_operation = 8000;
        /* This is intentionally high because it accounts for a retrieve with
         * wait for a delta to guarantee coherence.
         */
        int timeout_hooking_operation = 8000;
        /* This is intentionally high because we know nothing about module hooking.
         */
        if (r is EvaluateEnterRequest) return timeout_hooking_operation;
        if (r is BeginEnterRequest) return timeout_hooking_operation;
        if (r is CompletedEnterRequest) return timeout_hooking_operation;
        if (r is AbortEnterRequest) return timeout_hooking_operation;
        if (r is NumberOfNodesRequest) return timeout_write_operation;
        if (r is SetHookingMemoryRequest) return timeout_write_operation;
        if (r is ReserveEnterRequest) return timeout_write_operation;
        if (r is DeleteReserveEnterRequest) return timeout_write_operation;
        if (r is GetHookingMemoryRequest) return 1000;
        if (r is ReplicaRequest) return 1000;
        assert_not_reached();
    }

    internal class CoordClient : PeerClient
    {
        private CoordinatorManager mgr;
        public CoordClient(Gee.List<int> gsizes, PeersManager peers_manager, CoordinatorManager mgr)
        {
            base(CoordService.coordinator_p_id, gsizes, peers_manager);
            this.mgr = mgr;
        }

        /** 32 bit Fowler/Noll/Vo hash
          */
        private uint32 fnv_32(uint8[] buf)
        {
            uint32 hval = (uint32)2166136261;
            foreach (uint8 c in buf)
            {
                hval += (hval<<1) + (hval<<4) + (hval<<7) + (hval<<8) + (hval<<24);
                hval ^= c;
            }
            return hval;
        }

        /** 64 bit Fowler/Noll/Vo hash
          */
        private uint64 fnv_64(uint8[] buf)
        {
            uint64 hval = (uint64)0xcbf29ce484222325;
            foreach (uint8 c in buf)
            {
                hval += (hval<<1) + (hval<<4) + (hval<<5) + (hval<<7) + (hval<<8) + (hval<<40);
                hval ^= c;
            }
            return hval;
        }

        protected override uint64 hash_from_key(Object k, uint64 top)
        {
            assert(k is CoordinatorKey);
            CoordinatorKey _k = (CoordinatorKey)k;
            uint64 hash = fnv_64(@"$(_k.lvl)".data);
            return hash % (top+1);
        }

        public override Gee.List<int> perfect_tuple(Object k)
        {
            assert(k is CoordinatorKey);
            CoordinatorKey _k = (CoordinatorKey)k;
            int lvl = _k.lvl;
            var ret = new ArrayList<int>();
            for (int i = 0; i < lvl; i++) ret.add(0);
            return ret;
        }

        // ...

        /* Client calling functions
         */

        public int get_n_nodes()
        {
            CoordinatorKey k = new CoordinatorKey(mgr.levels);
            NumberOfNodesRequest r = new NumberOfNodesRequest();
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                warning("CoordClient: get_n_nodes: Got 'no participants', the service is not optional.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            } catch (PeersDatabaseError e) {
                warning("CoordClient: get_n_nodes: Got 'database error'.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            // unexpected class
            if (resp == null)
            {
                warning(@"CoordClient: get_n_nodes: Got unexpected null.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            else if (! (resp is NumberOfNodesResponse))
            {
                warning(@"CoordClient: get_n_nodes: Got unexpected class $(resp.get_type().name()).");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            return ((NumberOfNodesResponse)resp).n_nodes;
        }

        [NoReturn]
        private void throw_proxy_error(string msg) throws ProxyError
        {
            warning(msg);
            throw new ProxyError.GENERIC(msg);
        }

        public Object evaluate_enter(int lvl, Object evaluate_enter_data) throws ProxyError
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            EvaluateEnterRequest r = new EvaluateEnterRequest();
            r.lvl = lvl;
            r.evaluate_enter_data = evaluate_enter_data;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                throw_proxy_error("CoordClient: evaluate_enter: Got 'no participants', the service is not optional.");
            } catch (PeersDatabaseError e) {
                throw_proxy_error("CoordClient: evaluate_enter: Got 'database error', impossible for a proxy operation.");
            }
            if (resp is EvaluateEnterResponse)
            {
                return ((EvaluateEnterResponse)resp).evaluate_enter_result;
            }
            // unexpected class
            if (resp == null)
                throw_proxy_error(@"CoordClient: evaluate_enter(lvl=$(lvl)): Got unexpected null.");
            else
                throw_proxy_error(@"CoordClient: evaluate_enter(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
        }

        public Object begin_enter(int lvl, Object begin_enter_data) throws ProxyError
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            BeginEnterRequest r = new BeginEnterRequest();
            r.lvl = lvl;
            r.begin_enter_data = begin_enter_data;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                throw_proxy_error("CoordClient: begin_enter: Got 'no participants', the service is not optional.");
            } catch (PeersDatabaseError e) {
                throw_proxy_error("CoordClient: begin_enter: Got 'database error', impossible for a proxy operation.");
            }
            if (resp is BeginEnterResponse)
            {
                return ((BeginEnterResponse)resp).begin_enter_result;
            }
            // unexpected class
            if (resp == null)
                throw_proxy_error(@"CoordClient: begin_enter(lvl=$(lvl)): Got unexpected null.");
            else
                throw_proxy_error(@"CoordClient: begin_enter(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
        }

        public Object completed_enter(int lvl, Object completed_enter_data) throws ProxyError
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            CompletedEnterRequest r = new CompletedEnterRequest();
            r.lvl = lvl;
            r.completed_enter_data = completed_enter_data;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                throw_proxy_error("CoordClient: completed_enter: Got 'no participants', the service is not optional.");
            } catch (PeersDatabaseError e) {
                throw_proxy_error("CoordClient: completed_enter: Got 'database error', impossible for a proxy operation.");
            }
            if (resp is CompletedEnterResponse)
            {
                return ((CompletedEnterResponse)resp).completed_enter_result;
            }
            // unexpected class
            if (resp == null)
                throw_proxy_error(@"CoordClient: completed_enter(lvl=$(lvl)): Got unexpected null.");
            else
                throw_proxy_error(@"CoordClient: completed_enter(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
        }

        public Object abort_enter(int lvl, Object abort_enter_data) throws ProxyError
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            AbortEnterRequest r = new AbortEnterRequest();
            r.lvl = lvl;
            r.abort_enter_data = abort_enter_data;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                throw_proxy_error("CoordClient: abort_enter: Got 'no participants', the service is not optional.");
            } catch (PeersDatabaseError e) {
                throw_proxy_error("CoordClient: abort_enter: Got 'database error', impossible for a proxy operation.");
            }
            if (resp is AbortEnterResponse)
            {
                return ((AbortEnterResponse)resp).abort_enter_result;
            }
            // unexpected class
            if (resp == null)
                throw_proxy_error(@"CoordClient: abort_enter(lvl=$(lvl)): Got unexpected null.");
            else
                throw_proxy_error(@"CoordClient: abort_enter(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
        }

        public void set_hooking_memory(int lvl, Object memory) throws ProxyError
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            SetHookingMemoryRequest r = new SetHookingMemoryRequest();
            r.lvl = lvl;
            r.hooking_memory = memory;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                throw_proxy_error("CoordClient: set_hooking_memory: Got 'no participants', the service is not optional.");
            } catch (PeersDatabaseError e) {
                throw_proxy_error("CoordClient: set_hooking_memory: Got 'database error'.");
            }
            // unexpected class
            if (resp == null)
                throw_proxy_error(@"CoordClient: set_hooking_memory(lvl=$(lvl)): Got unexpected null.");
            else if (! (resp is SetHookingMemoryResponse))
                throw_proxy_error(@"CoordClient: set_hooking_memory(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
        }

        public Object get_hooking_memory(int lvl) throws ProxyError
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            GetHookingMemoryRequest r = new GetHookingMemoryRequest();
            r.lvl = lvl;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                throw_proxy_error("CoordClient: get_hooking_memory: Got 'no participants', the service is not optional.");
            } catch (PeersDatabaseError e) {
                throw_proxy_error("CoordClient: get_hooking_memory: Got 'database error'.");
            }
            // unexpected class
            if (resp == null)
                throw_proxy_error(@"CoordClient: get_hooking_memory(lvl=$(lvl)): Got unexpected null.");
            else if (! (resp is GetHookingMemoryResponse))
                throw_proxy_error(@"CoordClient: get_hooking_memory(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
            return ((GetHookingMemoryResponse)resp).hooking_memory;
        }

        public void reserve(int lvl, int reserve_request_id, out int new_pos, out int new_eldership)
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            ReserveEnterRequest r = new ReserveEnterRequest();
            r.lvl = lvl;
            r.reserve_request_id = reserve_request_id;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                warning("CoordClient: reserve: Got 'no participants', the service is not optional.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            } catch (PeersDatabaseError e) {
                warning("CoordClient: reserve: Got 'database error'.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            // unexpected class
            if (resp == null)
            {
                warning(@"CoordClient: reserve(lvl=$(lvl)): Got unexpected null.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            else if (! (resp is ReserveEnterResponse))
            {
                warning(@"CoordClient: reserve(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            new_pos = ((ReserveEnterResponse)resp).new_pos;
            new_eldership = ((ReserveEnterResponse)resp).new_eldership;
        }

        public void delete_reserve(int lvl, int reserve_request_id)
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            DeleteReserveEnterRequest r = new DeleteReserveEnterRequest();
            r.lvl = lvl;
            r.reserve_request_id = reserve_request_id;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                warning("CoordClient: delete_reserve: Got 'no participants', the service is not optional.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            } catch (PeersDatabaseError e) {
                warning("CoordClient: delete_reserve: Got 'database error'.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            // unexpected class
            if (resp == null)
            {
                warning(@"CoordClient: delete_reserve(lvl=$(lvl)): Got unexpected null.");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
            else if (! (resp is DeleteReserveEnterResponse))
            {
                warning(@"CoordClient: delete_reserve(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
                error("This should happen when another node is malicious or bugged. Not for an error on this node.\n" +
                    "First make it work when the nodes are all right. After, we'll try and find a correct behaviour for a node\n" +
                    "that receives bad answers from the network."); // TODO
            }
        }
    }
}
