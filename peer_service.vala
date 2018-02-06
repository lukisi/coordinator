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
        internal CoordinatorManager mgr;
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
            return peers_manager.fixed_keys_db_on_request(fkdd, req, client_tuple.size);
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
            Gee.List<int> ret = base.perfect_tuple(k);
            if (lvl < ret.size) ret = ret.slice(0, lvl);
            return ret;
        }

        // ...

        /* Client calling functions
         */
        public Object evaluate_enter(int lvl, Object evaluate_enter_data)
        {
            CoordinatorKey k = new CoordinatorKey(lvl);
            EvaluateEnterRequest r = new EvaluateEnterRequest();
            r.lvl = lvl;
            r.evaluate_enter_data = evaluate_enter_data;
            IPeersResponse resp;
            try {
                resp = this.call(k, r, timeout_exec_for_request(r));
            } catch (PeersNoParticipantsInNetworkError e) {
                error("CoordClient: evaluate_enter: Got 'no participants', the service is not optional.");
            } catch (PeersDatabaseError e) {
                error("CoordClient: evaluate_enter: Got 'database error', impossible for a proxy operation.");
            }
            if (resp is EvaluateEnterResponse)
            {
                return ((EvaluateEnterResponse)resp).evaluate_enter_result;
            }
            // unexpected class
            if (resp == null)
                warning(@"CoordClient: evaluate_enter(lvl=$(lvl)): Got unexpected null.");
            else
                warning(@"CoordClient: evaluate_enter(lvl=$(lvl)): Got unexpected class $(resp.get_type().name()).");
            error("Handling of bad response not implemented yet.");
        }
    }
}
