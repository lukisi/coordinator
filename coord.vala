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

        public CoordinatorManager(/*...*/)
        {
            //...
        }

        public void bootstrap_completed(PeersManager peers_manager, ICoordinatorMap map)
        {
            //...
        }

        // ...

        public Object evaluate_enter(int lvl, Object evaluate_enter_data)
        {
            error("not implemented yet.");
        }

        public Object begin_enter(int lvl, Object begin_enter_data)
        {
            error("not implemented yet.");
        }

        public Object completed_enter(int lvl, Object completed_enter_data)
        {
            error("not implemented yet.");
        }

        public Object abort_enter(int lvl, Object abort_enter_data)
        {
            error("not implemented yet.");
        }

        public Object get_hooking_memory(int lvl)
        {
            error("not implemented yet.");
        }

        public void set_hooking_memory(int lvl, Object memory)
        {
            error("not implemented yet.");
        }


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
