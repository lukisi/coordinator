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
    internal class CoordService : PeerService
    {
        internal const int coordinator_p_id = 1;
        private const int msec_ttl_new_reservation = 60000; // for new Booking
        private const int q_replica_new_reservation = 15; // for replicas

        private int levels;
        private PeersManager peers_manager;
        private CoordinatorManager mgr;
        private CoordDatabaseDescriptor fkdd;

        public CoordService
        (int levels, PeersManager peers_manager, CoordinatorManager mgr,
         int new_gnode_level, int guest_gnode_level, CoordService? prev_id)
        {
            base(coordinator_p_id, false);
            this.levels = levels;
            this.peers_manager = peers_manager;
            this.mgr = mgr;
            this.fkdd = new CoordDatabaseDescriptor(this);
 
            peers_manager.register(this);
            // launch fixed_keys_db_on_startup in a tasklet
            StartFixedKeysDbHandlerTasklet ts = new StartFixedKeysDbHandlerTasklet();
            ts.t = this;
            ts.new_gnode_level = new_gnode_level;
            ts.guest_gnode_level = guest_gnode_level;
            ts.prev_id = prev_id;
            tasklet.spawn(ts);
        }
        private class StartFixedKeysDbHandlerTasklet : Object, ITaskletSpawnable
        {
            public CoordService t;
            public int new_gnode_level;
            public int guest_gnode_level;
            public CoordService? prev_id;
            public void * func()
            {
                t.tasklet_start_fixed_keys_db_handler
                    (new_gnode_level, guest_gnode_level, prev_id);
                return null;
            }
        }
        private void tasklet_start_fixed_keys_db_handler
        (int new_gnode_level, int guest_gnode_level, CoordService? prev_id)
        {
            IFixedKeysDatabaseDescriptor? prev_id_fkdd = null;
            if (prev_id != null) prev_id_fkdd = prev_id.fkdd;
            peers_manager.fixed_keys_db_on_startup
                (fkdd, coordinator_p_id, prev_id_fkdd);
        }

        public override IPeersResponse exec(IPeersRequest req, Gee.List<int> client_tuple) throws PeersRefuseExecutionError, PeersRedoFromStartError
        {
            error("not implemented yet.");
        }

        // ...
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
            Gee.List<int> ret = base.perfect_tuple(k);
            if (lvl < ret.size) ret = ret.slice(0, lvl);
            return ret;
        }

        // ...
    }
}
