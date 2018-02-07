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

    internal ITasklet tasklet;
    public class CoordinatorManager : Object,
                                      ICoordinatorManagerSkeleton
    {
        public static void init(ITasklet _tasklet)
        {
            // Register serializable types
            //typeof(Timer).class_peek();
            //typeof(Booking).class_peek();  ...
            tasklet = _tasklet;
        }

        private int levels;
        private ArrayList<int> gsizes;
        //...
        internal IEvaluateEnterHandler evaluate_enter_handler;
        internal IBeginEnterHandler begin_enter_handler;
        internal ICompletedEnterHandler completed_enter_handler;
        internal IAbortEnterHandler abort_enter_handler;
        //...
        private PeersManager peers_manager;
        private ICoordinatorMap map;

        public CoordinatorManager(/*...,*/
            Gee.List<int> gsizes,
            IEvaluateEnterHandler evaluate_enter_handler,
            IBeginEnterHandler begin_enter_handler,
            ICompletedEnterHandler completed_enter_handler,
            IAbortEnterHandler abort_enter_handler/*, ...*/)
        {
            this.gsizes = new ArrayList<int>();
            this.gsizes.add_all(gsizes);
            levels = gsizes.size;
            assert(levels > 0);
            //...
            this.evaluate_enter_handler = evaluate_enter_handler;
            this.begin_enter_handler = begin_enter_handler;
            this.completed_enter_handler = completed_enter_handler;
            this.abort_enter_handler = abort_enter_handler;
            //...
        }

        public void bootstrap_completed(PeersManager peers_manager, ICoordinatorMap map)
        {
            //...
            this.peers_manager = peers_manager;
            this.map = map;
            //...
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
        public Object get_hooking_memory(int lvl)
        {
            error("not implemented yet.");
        }

        public void set_hooking_memory(int lvl, Object memory)
        {
            error("not implemented yet.");
        }

        /* Remotable methods
         */
        public void execute_finish_migration(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject finish_migration_data, CallerInfo? caller = null)
        {
            error("not implemented yet.");
        }

        public void execute_prepare_migration(ICoordTupleGNode tuple, int fp_id, int propagation_id, int lvl,
            ICoordObject prepare_migration_data, CallerInfo? caller = null)
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
