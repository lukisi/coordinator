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
    public errordomain ProxyError {
        GENERIC
    }

    public errordomain NotCoordinatorNodeError {
        GENERIC
    }

    internal ITasklet tasklet;
    public class CoordinatorManager : Object,
                                      ICoordinatorManagerSkeleton
    {
        public static void init(ITasklet _tasklet)
        {
            // Register serializable types
            typeof(SerTimer).class_peek();
            typeof(CoordinatorKey).class_peek();
            typeof(Booking).class_peek();
            typeof(CoordGnodeMemory).class_peek();
            typeof(NumberOfNodesRequest).class_peek();
            typeof(NumberOfNodesResponse).class_peek();
            typeof(EvaluateEnterRequest).class_peek();
            typeof(EvaluateEnterResponse).class_peek();
            typeof(BeginEnterRequest).class_peek();
            typeof(BeginEnterResponse).class_peek();
            typeof(CompletedEnterRequest).class_peek();
            typeof(CompletedEnterResponse).class_peek();
            typeof(AbortEnterRequest).class_peek();
            typeof(AbortEnterResponse).class_peek();
            typeof(GetHookingMemoryRequest).class_peek();
            typeof(GetHookingMemoryResponse).class_peek();
            typeof(SetHookingMemoryRequest).class_peek();
            typeof(SetHookingMemoryResponse).class_peek();
            typeof(ReserveEnterRequest).class_peek();
            typeof(ReserveEnterResponse).class_peek();
            typeof(DeleteReserveEnterRequest).class_peek();
            typeof(DeleteReserveEnterResponse).class_peek();
            typeof(ReplicaRequest).class_peek();
            typeof(ReplicaResponse).class_peek();
            tasklet = _tasklet;
        }

        public static void init_rngen(IRandomNumberGenerator? rngen=null, uint32? seed=null)
        {
            PRNGen.init_rngen(rngen, seed);
        }

        internal int levels;
        internal ArrayList<int> gsizes;
        internal int? guest_gnode_level;
        internal int? host_gnode_level;
        internal CoordinatorManager? prev_coord_mgr;

        internal IEvaluateEnterHandler evaluate_enter_handler;
        internal IBeginEnterHandler begin_enter_handler;
        internal ICompletedEnterHandler completed_enter_handler;
        internal IAbortEnterHandler abort_enter_handler;
        internal IPropagationHandler propagation_handler;
        private Gee.List<int> propagation_id_list;
        internal IStubFactory stub_factory;

        internal PeersManager? peers_manager; // This will be given a value after qspn_bootstrap.
        internal ICoordinatorMap? map; // This will be given a value after qspn_bootstrap.
        internal CoordService? service; // This might remain null (or become null) if the identity is not main.

        public CoordinatorManager(
            Gee.List<int> gsizes,
            IEvaluateEnterHandler evaluate_enter_handler,
            IBeginEnterHandler begin_enter_handler,
            ICompletedEnterHandler completed_enter_handler,
            IAbortEnterHandler abort_enter_handler,
            IPropagationHandler propagation_handler,
            IStubFactory stub_factory,
            int? guest_gnode_level,
            int? host_gnode_level,
            CoordinatorManager? prev_coord_mgr)
        {
            this.gsizes = new ArrayList<int>();
            this.gsizes.add_all(gsizes);
            levels = gsizes.size;
            assert(levels > 0);
            if (guest_gnode_level == null)
            {
                assert(host_gnode_level == null);
                assert(prev_coord_mgr == null);
            }
            else
            {
                assert(host_gnode_level != null);
                assert(prev_coord_mgr != null);
            }
            this.guest_gnode_level = guest_gnode_level;
            this.host_gnode_level = host_gnode_level;
            this.prev_coord_mgr = prev_coord_mgr;

            this.evaluate_enter_handler = evaluate_enter_handler;
            this.begin_enter_handler = begin_enter_handler;
            this.completed_enter_handler = completed_enter_handler;
            this.abort_enter_handler = abort_enter_handler;
            this.propagation_handler = propagation_handler;
            propagation_id_list = new ArrayList<int>();
            this.stub_factory = stub_factory;

            peers_manager = null;
            map = null;
            service = null;
        }

        public void bootstrap_completed(PeersManager peers_manager, ICoordinatorMap map, bool is_main_id)
        {
            this.peers_manager = peers_manager;
            this.map = map;
            if (is_main_id)
            {
                CoordService? prev_service = null;
                if (prev_coord_mgr == null) prev_service = prev_coord_mgr.service;
                service = new CoordService(peers_manager, this, prev_service);
            }
        }

        public void gone_connectivity()
        {
            service = null;
        }

        /* Proxy methods for module Hooking
         */
        public Object evaluate_enter(int lvl, Object evaluate_enter_data) throws ProxyError
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            return client.evaluate_enter(lvl, evaluate_enter_data);
        }

        public Object begin_enter(int lvl, Object begin_enter_data) throws ProxyError
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            return client.begin_enter(lvl, begin_enter_data);
        }

        public Object completed_enter(int lvl, Object completed_enter_data) throws ProxyError
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            return client.completed_enter(lvl, completed_enter_data);
        }

        public Object abort_enter(int lvl, Object abort_enter_data) throws ProxyError
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            return client.abort_enter(lvl, abort_enter_data);
        }

        /* Handle g-node memory for module Hooking
         */
        public Object get_hooking_memory(int lvl) throws NotCoordinatorNodeError, ProxyError
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            CoordinatorKey k = new CoordinatorKey(lvl);
            if (! client.am_i_servant_for(k))
                throw new NotCoordinatorNodeError.GENERIC("CoordinatorManager: get_hooking_memory: Only servant can access memory for module Hooking.");
            return client.get_hooking_memory(lvl);
        }

        public void set_hooking_memory(int lvl, Object memory) throws NotCoordinatorNodeError, ProxyError
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            CoordinatorKey k = new CoordinatorKey(lvl);
            if (! client.am_i_servant_for(k))
                throw new NotCoordinatorNodeError.GENERIC("CoordinatorManager: get_hooking_memory: Only servant can access memory for module Hooking.");
            client.set_hooking_memory(lvl, memory);
        }

        /* Handle reservations.
         */
        public Reservation reserve(int lvl, int reserve_request_id)
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            int new_pos;
            int new_eldership;
            client.reserve(lvl, reserve_request_id, out new_pos, out new_eldership);
            Reservation ret = new Reservation();
            ret.new_pos = new_pos;
            ret.new_eldership = new_eldership;
            return ret;
        }

        public void delete_reserve(int lvl, int reserve_request_id)
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            client.delete_reserve(lvl, reserve_request_id);
        }

        /* Request "number of nodes" to the Coordinator of the whole network.
         */
        public int get_n_nodes()
        {
            CoordClient client = new CoordClient(gsizes, peers_manager, this);
            return client.get_n_nodes();
        }

        /* Methods for propagation
         */
        private void prepare_propagation(int lvl, out TupleGnode tuple, out int fp_id, out int propagation_id)
        {
            tuple = new TupleGnode();
            tuple.tuple = new ArrayList<int>();
            for (int i = lvl; i < levels; i++) tuple.tuple.add(map.get_my_pos(i));
            fp_id = map.get_fp_id(lvl);
            propagation_id = PRNGen.int_range(1, int.MAX);
            propagation_id_list.add(propagation_id);
        }
        private void propagation_cleanup(int propagation_id)
        {
            PropagationCleanupTasklet ts = new PropagationCleanupTasklet();
            ts.t = this;
            ts.propagation_id = propagation_id;
            tasklet.spawn(ts);
        }
        private class PropagationCleanupTasklet : Object, ITaskletSpawnable
        {
            public CoordinatorManager t;
            public int propagation_id;
            public void * func()
            {
                t.tasklet_propagation_cleanup(propagation_id);
                return null;
            }
        }
        private void tasklet_propagation_cleanup(int propagation_id)
        {
            tasklet.ms_wait(200000);
            propagation_id_list.remove(propagation_id);
        }

        public void prepare_migration(int lvl, Object prepare_migration_data)
        {
            TupleGnode tuple;
            int fp_id;
            int propagation_id;
            prepare_propagation(lvl, out tuple, out fp_id, out propagation_id);
            Gee.List<ICoordinatorManagerStub> stubs = stub_factory.get_stub_for_each_neighbor();
            // TODO Place the calls in a bunch of tasklets, then wait for all of them to finish.
            foreach (ICoordinatorManagerStub stub in stubs)
            {
                try {
                    stub.execute_prepare_migration(tuple, fp_id, propagation_id, lvl, new CoordinatorObject(prepare_migration_data));
                } catch (StubError e) {
                    // nop.
                } catch (DeserializeError e) {
                    // nop.
                }
            }
            propagation_handler.prepare_migration(lvl, prepare_migration_data);
            propagation_cleanup(propagation_id);
        }

        public void finish_migration(int lvl, Object finish_migration_data)
        {
            TupleGnode tuple;
            int fp_id;
            int propagation_id;
            prepare_propagation(lvl, out tuple, out fp_id, out propagation_id);
            ICoordinatorManagerStub stub = stub_factory.get_stub_for_all_neighbors();
            try {
                stub.execute_finish_migration(tuple, fp_id, propagation_id, lvl, new CoordinatorObject(finish_migration_data));
            } catch (StubError e) {
                // nop.
            } catch (DeserializeError e) {
                // nop.
            }
            CallFinishMigrationTasklet ts = new CallFinishMigrationTasklet();
            ts.t = this;
            ts.lvl = lvl;
            ts.finish_migration_data = finish_migration_data;
            ts.propagation_id = propagation_id;
            tasklet.spawn(ts);
        }
        private class CallFinishMigrationTasklet : Object, ITaskletSpawnable
        {
            public CoordinatorManager t;
            public int lvl;
            public Object finish_migration_data;
            public int propagation_id;
            public void * func()
            {
                t.tasklet_call_finish_migration(lvl, finish_migration_data, propagation_id);
                return null;
            }
        }
        private void tasklet_call_finish_migration(int lvl, Object finish_migration_data, int propagation_id)
        {
            propagation_handler.finish_migration(lvl, finish_migration_data);
            propagation_cleanup(propagation_id);
        }

        public void we_have_splitted(int lvl, Object we_have_splitted_data)
        {
            TupleGnode tuple;
            int fp_id;
            int propagation_id;
            prepare_propagation(lvl, out tuple, out fp_id, out propagation_id);
            ICoordinatorManagerStub stub = stub_factory.get_stub_for_all_neighbors();
            try {
                stub.execute_we_have_splitted(tuple, fp_id, propagation_id, lvl, new CoordinatorObject(we_have_splitted_data));
            } catch (StubError e) {
                // nop.
            } catch (DeserializeError e) {
                // nop.
            }
            CallWeHaveSplittedTasklet ts = new CallWeHaveSplittedTasklet();
            ts.t = this;
            ts.lvl = lvl;
            ts.we_have_splitted_data = we_have_splitted_data;
            ts.propagation_id = propagation_id;
            tasklet.spawn(ts);
        }
        private class CallWeHaveSplittedTasklet : Object, ITaskletSpawnable
        {
            public CoordinatorManager t;
            public int lvl;
            public Object we_have_splitted_data;
            public int propagation_id;
            public void * func()
            {
                t.tasklet_call_we_have_splitted(lvl, we_have_splitted_data, propagation_id);
                return null;
            }
        }
        private void tasklet_call_we_have_splitted(int lvl, Object we_have_splitted_data, int propagation_id)
        {
            propagation_handler.we_have_splitted(lvl, we_have_splitted_data);
            propagation_cleanup(propagation_id);
        }

        /* Remotable methods
         */
        private bool check_propagation(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject prepare_migration_data, out Object _prepare_migration_data, out TupleGnode _tuple)
        {
            if (! (prepare_migration_data is CoordinatorObject)) tasklet.exit_tasklet(); // bad call.
            _prepare_migration_data = ((CoordinatorObject)prepare_migration_data).object;
            if (! (tuple is TupleGnode)) tasklet.exit_tasklet(); // bad call.
            _tuple = (TupleGnode)tuple;
            if (_tuple.tuple == null) tasklet.exit_tasklet(); // bad call.
            if (_tuple.tuple.size + lvl != levels) tasklet.exit_tasklet(); // bad call.

            if (propagation_id in propagation_id_list) return false; // already executed.
            for (int i = lvl; i < levels; i++) if (_tuple.tuple[i-lvl] != map.get_my_pos(i)) return false; // not my g-node.
            if (fp_id != map.get_fp_id(lvl)) return false; // not my g-node.

            propagation_id_list.add(propagation_id);
            return true; // go on.
        }

        public void execute_prepare_migration(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject prepare_migration_data, CallerInfo? caller = null)
        {
            Object _prepare_migration_data;
            TupleGnode _tuple;
            bool go_on = check_propagation(tuple, fp_id, propagation_id, lvl, prepare_migration_data,
                out _prepare_migration_data, out _tuple);
            if (! go_on) return;

            Gee.List<ICoordinatorManagerStub> stubs = stub_factory.get_stub_for_each_neighbor();
            // TODO Place the calls in a bunch of tasklets, then wait for all of them to finish.
            foreach (ICoordinatorManagerStub stub in stubs)
            {
                try {
                    stub.execute_prepare_migration(tuple, fp_id, propagation_id, lvl, prepare_migration_data);
                } catch (StubError e) {
                    // nop.
                } catch (DeserializeError e) {
                    // nop.
                }
            }
            propagation_handler.prepare_migration(lvl, _prepare_migration_data);
            propagation_cleanup(propagation_id);
        }

        public void execute_finish_migration(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject finish_migration_data, CallerInfo? caller = null)
        {
            Object _finish_migration_data;
            TupleGnode _tuple;
            bool go_on = check_propagation(tuple, fp_id, propagation_id, lvl, finish_migration_data,
                out _finish_migration_data, out _tuple);
            if (! go_on) return;

            ICoordinatorManagerStub stub = stub_factory.get_stub_for_all_neighbors();
            try {
                stub.execute_finish_migration(tuple, fp_id, propagation_id, lvl, finish_migration_data);
            } catch (StubError e) {
                // nop.
            } catch (DeserializeError e) {
                // nop.
            }
            propagation_handler.finish_migration(lvl, _finish_migration_data);
            propagation_cleanup(propagation_id);
        }

        public void execute_we_have_splitted(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject we_have_splitted_data, CallerInfo? caller = null)
        {
            Object _we_have_splitted_data;
            TupleGnode _tuple;
            bool go_on = check_propagation(tuple, fp_id, propagation_id, lvl, we_have_splitted_data,
                out _we_have_splitted_data, out _tuple);
            if (! go_on) return;

            ICoordinatorManagerStub stub = stub_factory.get_stub_for_all_neighbors();
            try {
                stub.execute_we_have_splitted(tuple, fp_id, propagation_id, lvl, we_have_splitted_data);
            } catch (StubError e) {
                // nop.
            } catch (DeserializeError e) {
                // nop.
            }
            propagation_handler.we_have_splitted(lvl, _we_have_splitted_data);
            propagation_cleanup(propagation_id);
        }
    }
}
