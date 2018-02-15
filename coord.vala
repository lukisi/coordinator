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

        internal int levels;
        internal ArrayList<int> gsizes;
        internal int? guest_gnode_level;
        internal int? host_gnode_level;
        internal CoordinatorManager? prev_coord_mgr;
        //...
        internal IEvaluateEnterHandler evaluate_enter_handler;
        internal IBeginEnterHandler begin_enter_handler;
        internal ICompletedEnterHandler completed_enter_handler;
        internal IAbortEnterHandler abort_enter_handler;
        internal IPropagationHandler propagation_handler;
        //...
        internal PeersManager peers_manager;
        internal ICoordinatorMap map;
        internal CoordService? service;

        public CoordinatorManager(/*...,*/
            Gee.List<int> gsizes,
            int? guest_gnode_level,
            int? host_gnode_level,
            CoordinatorManager? prev_coord_mgr,
            IEvaluateEnterHandler evaluate_enter_handler,
            IBeginEnterHandler begin_enter_handler,
            ICompletedEnterHandler completed_enter_handler,
            IAbortEnterHandler abort_enter_handler,
            IPropagationHandler propagation_handler/*, ...*/)
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
            //...
            this.evaluate_enter_handler = evaluate_enter_handler;
            this.begin_enter_handler = begin_enter_handler;
            this.completed_enter_handler = completed_enter_handler;
            this.abort_enter_handler = abort_enter_handler;
            this.propagation_handler = propagation_handler;
            //...
            service = null;
        }

        public void bootstrap_completed(PeersManager peers_manager, ICoordinatorMap map)
        {
            this.peers_manager = peers_manager;
            this.map = map;
            CoordService? prev_service = null;
            if (prev_coord_mgr == null) prev_service = prev_coord_mgr.service;
            service = new CoordService(peers_manager, this, prev_service);
        }

        // ...

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
            error("not implemented yet.");
        }

        /* Request "number of nodes" to the Coordinator of the whole network.
         */
        public int get_n_nodes()
        {
            error("not implemented yet.");
        }

        /* Methods for propagation
         */
        public void prepare_migration(int lvl, Object prepare_migration_data)
        {
            error("not implemented yet.");
        }

        public void finish_migration(int lvl, Object finish_migration_data)
        {
            error("not implemented yet.");
        }

        public void we_have_splitted(int lvl, Object we_have_splitted_data)
        {
            error("not implemented yet.");
        }

        /* Remotable methods
         */
        public void execute_prepare_migration(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject prepare_migration_data, CallerInfo? caller = null)
        {
            error("not implemented yet.");
        }

        public void execute_finish_migration(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject finish_migration_data, CallerInfo? caller = null)
        {
            error("not implemented yet.");
        }

        public void execute_we_have_splitted(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject we_have_splitted_data, CallerInfo? caller = null)
        {
            error("not implemented yet.");
        }

    }
}
