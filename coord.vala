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
    public interface ICoordinatorMap : Object
    {
        public abstract int get_levels();
        public abstract int get_gsize(int lvl);
        public abstract int get_n_nodes();
        public abstract Gee.List<int> get_free_pos(int lvl);
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

        public CoordinatorManager(/*...*/)
        {
            //...
        }

        public void bootstrap_completed(PeersManager peers_manager, ICoordinatorMap map)
        {
            //...
        }

        // ...
    }

    internal class CoordDatabaseDescriptor : Object, IDatabaseDescriptor, IFixedKeysDatabaseDescriptor
    {
        // ...
    }

    internal class CoordService : PeerService
    {
        internal const int coordinator_p_id = 1;
        private const int msec_ttl_new_reservation = 60000; // for new Booking
        private const int q_replica_new_reservation = 15;; // for replicas

        // ...
    }

    internal class CoordClient : PeerClient
    {
        private CoordinatorManager mgr;
        public CoordinatorClient(Gee.List<int> gsizes, PeersManager peers_manager, CoordinatorManager mgr)
        {
            base(CoordinatorService.coordinator_p_id, gsizes, peers_manager);
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
