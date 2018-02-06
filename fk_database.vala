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
        private CoordService t;
        public CoordDatabaseDescriptor(CoordService t)
        {
            this.t = t;
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

        public Gee.List<int> evaluate_hash_node(Object k)
        {
            error("not implemented yet.");
        }

        public IPeersResponse execute(IPeersRequest r) throws PeersRefuseExecutionError, PeersRedoFromStartError
        {
            if (r is EvaluateEnterRequest)
            {
                EvaluateEnterRequest _r = (EvaluateEnterRequest)r;
                EvaluateEnterResponse ret = new EvaluateEnterResponse();
                ret.evaluate_enter_result =
                    t.mgr.evaluate_enter_handler.evaluate_enter(_r.lvl, _r.evaluate_enter_data);
                return ret;
            }
            // TODO handle. maybe tasklet.end_tasklet();
            error("not implemented yet.");
        }

        public Object get_key_from_request(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public Object get_record_for_key(Object k)
        {
            error("not implemented yet.");
        }

        public int get_timeout_exec(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public bool is_insert_request(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public bool is_read_only_request(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public bool is_replica_delete_request(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public bool is_replica_value_request(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public bool is_update_request(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public bool is_valid_key(Object k)
        {
            error("not implemented yet.");
        }

        public bool is_valid_record(Object k, Object rec)
        {
            error("not implemented yet.");
        }

        public bool key_equal_data(Object k1, Object k2)
        {
            error("not implemented yet.");
        }

        public uint key_hash_data(Object k)
        {
            error("not implemented yet.");
        }

        public bool my_records_contains(Object k)
        {
            error("not implemented yet.");
        }

        public IPeersResponse prepare_response_not_found(IPeersRequest r)
        {
            error("not implemented yet.");
        }

        public IPeersResponse prepare_response_not_free(IPeersRequest r, Object rec)
        {
            error("not implemented yet.");
        }

        public void set_record_for_key(Object k, Object rec)
        {
            error("not implemented yet.");
        }

        public Object get_default_record_for_key(Object k)
        {
            error("not implemented yet.");
        }

        public Gee.List<Object> get_full_key_domain()
        {
            error("not implemented yet.");
        }
    }

}
