/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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
using Netsukuku.ModRpc;
using zcd.ModRpc;
using LibCoordInternals;

namespace debugging_coord
{
    internal string list_int(Gee.List<int> a)
    {
        string next = "";
        string ret = "";
        foreach (int i in a)
        {
            ret += @"$(next)$(i)";
            next = ", ";
        }
        return @"[$(ret)]";
    }
}

namespace Netsukuku
{
    public errordomain CoordinatorStubNotWorkingError {
        GENERIC
    }

    public interface ICoordinatorMap : Object
    {
        public abstract int get_levels();
        public abstract int get_gsize(int lvl);
        public abstract int get_eldership(int lvl);
        public abstract int get_my_pos(int lvl);
        public abstract Gee.List<int> get_free_pos(int lvl);
    }

    public interface ICoordinatorNeighborMap : Object
    {
        public abstract int get_levels();
        public abstract int get_gsize(int lvl);
        public abstract int get_free_pos_count(int lvl);
    }

    public interface ICoordinatorReservation : Object
    {
        public abstract int get_levels();
        public abstract int get_gsize(int lvl);
        public abstract int get_lvl();
        public abstract int get_pos();
        public abstract int get_eldership();
        public abstract int get_upper_pos(int lvl);
        public abstract int get_upper_eldership(int lvl);
    }

    internal class Booking : Object
    {
        public Booking(int pos, int msec_ttl)
        {
            this.pos = pos;
            ttl = new Timer(msec_ttl);
        }

        public int pos {get; set;}
        public Timer ttl {get; set;}
    }

    internal class Timer : Object
    {
        public Timer(int msec_ttl)
        {
            this.msec_ttl = msec_ttl;
        }

        public int msec_ttl {
            get {
                TimeVal lap = TimeVal();
                lap.get_current_time();
                long sec = lap.tv_sec - start.tv_sec;
                long usec = lap.tv_usec - start.tv_usec;
                if (usec < 0)
                {
                    usec += 1000000;
                    sec--;
                }
                long usec_lap = sec*1000000 + usec;
                long usec_ttl_now = _msec_ttl*1000 - usec_lap;
                return (int)(usec_ttl_now / 1000);
            }
            set {
                start = TimeVal();
                start.get_current_time();
                this._msec_ttl = value;
            }
        }

        private TimeVal start;
        private int _msec_ttl;

        public bool is_expired()
        {
            return msec_ttl < 0;
        }
    }

    internal class CoordinatorKey : Object
    {
        public int lvl {get; set;}
        public CoordinatorKey(int lvl)
        {
            this.lvl = lvl;
        }

        public static bool equal_data(CoordinatorKey k1, CoordinatorKey k2)
        {
            return k1.lvl == k2.lvl;
        }

        public static uint hash_data(CoordinatorKey k)
        {
            return @"$(k.lvl)".hash();
        }
    }

    internal class CoordinatorRecord : Object, Json.Serializable
    {
        public int lvl {get; set;}
        public Gee.List<Booking> booking_list {get; set;}
        public int max_eldership {get; set;}
        public CoordinatorRecord(int lvl, Gee.List<Booking> booking_list, int max_eldership)
        {
            this.lvl = lvl;
            this.max_eldership = max_eldership;
            this.booking_list = new ArrayList<Booking>((a,b) => a.pos == b.pos);
            this.booking_list.add_all(booking_list);
        }

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "lvl":
            case "max_eldership":
            case "max-eldership":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "booking_list":
            case "booking-list":
                try {
                    @value = deserialize_list_booking(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            default:
                return false;
            }
            return true;
        }

        public unowned GLib.ParamSpec find_property
        (string name)
        {
            return get_class().find_property(name);
        }

        public Json.Node serialize_property
        (string property_name,
         GLib.Value @value,
         GLib.ParamSpec pspec)
        {
            switch (property_name) {
            case "lvl":
            case "max_eldership":
            case "max-eldership":
                return serialize_int((int)@value);
            case "booking_list":
            case "booking-list":
                return serialize_list_booking((Gee.List<Booking>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class CoordinatorReserveRequest : Object, IPeersRequest
    {
        public int lvl {get; set;}
        public CoordinatorReserveRequest(int lvl)
        {
            this.lvl = lvl;
        }
    }

    internal class CoordinatorReserveResponse : Object, IPeersResponse
    {
        public CoordinatorReserveResponse.error(string error_domain, string error_code, string error_message)
        {
            this.error_domain = error_domain;
            this.error_code = error_code;
            this.error_message = error_message;
        }

        public CoordinatorReserveResponse.success(int pos, int eldership)
        {
            this.pos = pos;
            this.eldership = eldership;
        }

        public string error_domain {get; set; default = null;}
        public string error_code {get; set; default = null;}
        public string error_message {get; set; default = null;}
        public int pos {get; set;}
        public int eldership {get; set;}
    }

    internal class CoordinatorReplicaRecordRequest : Object, IPeersRequest
    {
        public CoordinatorRecord record {get; set;}
        public CoordinatorReplicaRecordRequest(CoordinatorRecord record)
        {
            this.record = record;
        }
    }

    internal class CoordinatorReplicaRecordSuccessResponse : Object, IPeersResponse
    {
    }

    internal class CoordinatorUnknownRequestResponse : Object, IPeersResponse
    {
    }

    internal int timeout_exec_for_request(IPeersRequest r)
    {
        int timeout_write_operation = 8000;
        /* This is intentionally high because it accounts for a retrieve with
         * wait for a delta to guarantee coherence.
         */
        if (r is CoordinatorReserveRequest) return timeout_write_operation;
        if (r is CoordinatorReplicaRecordRequest) return 1000;
        assert_not_reached();
    }

    internal class NeighborMap : Object, ICoordinatorNeighborMap, ICoordinatorNeighborMapMessage,
                                         zcd.ModRpc.ISerializable, Json.Serializable
    {
        public NeighborMap(Gee.List<int> gsizes, Gee.List<int> free_pos_count_list)
        {
            this.gsizes = new ArrayList<int>();
            this.gsizes.add_all(gsizes);
            this.free_pos_count_list = new ArrayList<int>();
            this.free_pos_count_list.add_all(free_pos_count_list);
            assert (check_deserialization());
        }

        public Gee.List<int> gsizes {get; set;}
        public Gee.List<int> free_pos_count_list {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "gsizes":
            case "free_pos_count_list":
            case "free-pos-count-list":
                try {
                    @value = deserialize_list_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            default:
                return false;
            }
            return true;
        }

        public unowned GLib.ParamSpec find_property
        (string name)
        {
            return get_class().find_property(name);
        }

        public Json.Node serialize_property
        (string property_name,
         GLib.Value @value,
         GLib.ParamSpec pspec)
        {
            switch (property_name) {
            case "gsizes":
            case "free_pos_count_list":
            case "free-pos-count-list":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }

        public int get_levels()
        {
            return gsizes.size;
        }

        public int get_gsize(int lvl)
        {
            return gsizes[lvl];
        }

        public int get_free_pos_count(int lvl)
        {
            return free_pos_count_list[lvl];
        }

        public bool check_deserialization()
        {
            if (gsizes == null) return false;
            if (free_pos_count_list == null) return false;
            if (gsizes.size == 0) return false;
            if (gsizes.size != free_pos_count_list.size) return false;
            for (int i = 0; i < gsizes.size; i++)
            {
                if (gsizes[i] <= 0) return false;
                if (free_pos_count_list[i] < 0) return false;
            }
            return true;
        }
    }

    internal class Reservation : Object, ICoordinatorReservation, ICoordinatorReservationMessage,
                                         zcd.ModRpc.ISerializable, Json.Serializable
    {
        public Reservation(int levels, Gee.List<int> gsizes,
                           int lvl, int pos, int eldership,
                           Gee.List<int> upper_pos, Gee.List<int> upper_elderships)
        {
            this.levels = levels;
            this.gsizes = new ArrayList<int>();
            this.gsizes.add_all(gsizes);
            this.lvl = lvl;
            this.pos = pos;
            this.eldership = eldership;
            this.upper_pos = new ArrayList<int>();
            this.upper_pos.add_all(upper_pos);
            this.upper_elderships = new ArrayList<int>();
            this.upper_elderships.add_all(upper_elderships);
            assert (check_deserialization());
        }

        public int levels {get; set;}
        public Gee.List<int> gsizes {get; set;}
        public int lvl {get; set;}
        public int pos {get; set;}
        public int eldership {get; set;}
        public Gee.List<int> upper_pos {get; set;}
        public Gee.List<int> upper_elderships {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "levels":
            case "lvl":
            case "pos":
            case "eldership":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "gsizes":
            case "upper_pos":
            case "upper-pos":
            case "upper_elderships":
            case "upper-elderships":
                try {
                    @value = deserialize_list_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            default:
                return false;
            }
            return true;
        }

        public unowned GLib.ParamSpec find_property
        (string name)
        {
            return get_class().find_property(name);
        }

        public Json.Node serialize_property
        (string property_name,
         GLib.Value @value,
         GLib.ParamSpec pspec)
        {
            switch (property_name) {
            case "levels":
            case "lvl":
            case "pos":
            case "eldership":
                return serialize_int((int)@value);
            case "gsizes":
            case "upper_pos":
            case "upper-pos":
            case "upper_elderships":
            case "upper-elderships":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }

        public int get_levels()
        {
            return levels;
        }

        public int get_gsize(int l)
        {
            assert(l >= 0);
            assert(l < levels);
            return gsizes[l];
        }

        public int get_lvl()
        {
            return lvl;
        }

        public int get_pos()
        {
            return pos;
        }

        public int get_eldership()
        {
            return eldership;
        }

        public int get_upper_pos(int l)
        {
            assert(l >= lvl + 1);
            assert(l < levels);
            return upper_pos[l-lvl-1];
        }

        public int get_upper_eldership(int l)
        {
            assert(l >= lvl + 1);
            assert(l < levels);
            return upper_elderships[l-lvl-1];
        }

        public bool check_deserialization()
        {
            if (levels <= 0) return false;
            if (gsizes == null) return false;
            if (gsizes.size != levels) return false;
            for (int i = 0; i < gsizes.size; i++)
            {
                if (gsizes[i] < 1) return false;
            }
            if (lvl < 0) return false;
            if (lvl >= levels) return false;
            if (pos < 0) return false;
            if (pos >= gsizes[lvl]) return false;
            if (eldership < 0) return false;
            if (upper_elderships == null) return false;
            if (upper_elderships.size != levels-lvl-1) return false;
            for (int i = 0; i < upper_elderships.size; i++)
            {
                if (upper_elderships[i] < 0) return false;
            }
            if (upper_pos == null) return false;
            if (upper_pos.size != levels-lvl-1) return false;
            for (int i = 0; i < upper_pos.size; i++)
            {
                if (upper_pos[i] < 0) return false;
                if (upper_pos[i] >= gsizes[lvl+i+1]) return false;
            }
            return true;
        }
    }

    internal INtkdTasklet tasklet;
    public class CoordinatorManager : Object,
                                      ICoordinatorManagerSkeleton
    {
        public static void init(INtkdTasklet _tasklet)
        {
            // Register serializable types
            typeof(Timer).class_peek();
            typeof(Booking).class_peek();
            typeof(CoordinatorKey).class_peek();
            typeof(CoordinatorRecord).class_peek();
            typeof(CoordinatorReserveRequest).class_peek();
            typeof(CoordinatorReserveResponse).class_peek();
            typeof(CoordinatorReplicaRecordRequest).class_peek();
            typeof(CoordinatorReplicaRecordSuccessResponse).class_peek();
            typeof(CoordinatorUnknownRequestResponse).class_peek();
            typeof(NeighborMap).class_peek();
            typeof(Reservation).class_peek();
            tasklet = _tasklet;
        }

        private int level_new_gnode;
        private PeersManager? peers_manager;
        internal ICoordinatorMap? map;
        private CoordinatorService? service;

        internal int levels {
            get {
                assert (map != null);
                return map.get_levels();
            }
        }
        private ArrayList<int> _gsizes;
        internal ArrayList<int> gsizes {
            get {
                assert (map != null);
                _gsizes = new ArrayList<int>();
                for (int i = 0; i < levels; i++)
                    _gsizes.add(map.get_gsize(i));
                return _gsizes;
            }
        }
        private ArrayList<int> _pos;
        internal ArrayList<int> pos {
            get {
                assert (map != null);
                _pos = new ArrayList<int>();
                for (int i = 0; i < levels; i++)
                    _pos.add(map.get_my_pos(i));
                return _pos;
            }
        }
        private ArrayList<int> _elderships;
        internal ArrayList<int> elderships {
            get {
                assert (map != null);
                _elderships = new ArrayList<int>();
                for (int i = 0; i < levels; i++)
                    _elderships.add(map.get_eldership(i));
                return _elderships;
            }
        }

        public CoordinatorManager(int level_new_gnode)
        {
            this.level_new_gnode = level_new_gnode;
            peers_manager = null;
            map = null;
            service = null;
        }

        public void bootstrap_completed(PeersManager peers_manager, ICoordinatorMap map)
        {
            this.peers_manager = peers_manager;
            this.map = map;
            service = new CoordinatorService(map.get_levels(), peers_manager, this, level_new_gnode);
        }

        public ICoordinatorNeighborMap get_neighbor_map
        (Netsukuku.ModRpc.ICoordinatorManagerStub stub)
        throws CoordinatorStubNotWorkingError, CoordinatorNodeNotReadyError
        {
            ICoordinatorNeighborMapMessage ret;
            try {
                ret = stub.retrieve_neighbor_map();
            }
            catch (zcd.ModRpc.StubError e) {
                throw new CoordinatorStubNotWorkingError.GENERIC(@"StubError: $(e.message)");
            }
            catch (zcd.ModRpc.DeserializeError e) {
                throw new CoordinatorStubNotWorkingError.GENERIC(@"DeserializeError: $(e.message)");
            }
            if (ret == null)
                throw new CoordinatorStubNotWorkingError.GENERIC(@"Returned null.");
            if (!(ret is ICoordinatorNeighborMap))
                throw new CoordinatorStubNotWorkingError.GENERIC(@"Returned unknown class $(ret.get_type().name())");
            return (ICoordinatorNeighborMap)ret;
        }

        public ICoordinatorReservation get_reservation
        (Netsukuku.ModRpc.ICoordinatorManagerStub stub, int lvl)
        throws CoordinatorStubNotWorkingError, CoordinatorNodeNotReadyError,
               CoordinatorInvalidLevelError, CoordinatorSaturatedGnodeError
        {
            if (lvl <= 0) error(@"CoordinatorManager.get_reservation: Bad lvl = $(lvl)");
            ICoordinatorReservationMessage ret;
            try {
                ret = stub.ask_reservation(lvl);
            }
            catch (zcd.ModRpc.StubError e) {
                throw new CoordinatorStubNotWorkingError.GENERIC(@"StubError: $(e.message)");
            }
            catch (zcd.ModRpc.DeserializeError e) {
                throw new CoordinatorStubNotWorkingError.GENERIC(@"DeserializeError: $(e.message)");
            }
            if (ret == null)
                throw new CoordinatorStubNotWorkingError.GENERIC(@"Returned null.");
            if (!(ret is ICoordinatorReservation))
                throw new CoordinatorStubNotWorkingError.GENERIC(@"Returned unknown class $(ret.get_type().name())");
            return (ICoordinatorReservation)ret;
        }

        /* Remotable methods */

        public ICoordinatorNeighborMapMessage retrieve_neighbor_map
        (zcd.ModRpc.CallerInfo? caller = null)
        throws CoordinatorNodeNotReadyError
        {
            if (map == null) throw new CoordinatorNodeNotReadyError.GENERIC("Node not bootstrapped yet.");
            ArrayList<int> nm_gsizes;
            ArrayList<int> nm_free_pos_count_list;
            int levels = map.get_levels();
            nm_gsizes = new ArrayList<int>();
            nm_free_pos_count_list = new ArrayList<int>();
            for (int l = 0; l < levels; l++)
            {
                nm_gsizes.add(map.get_gsize(l));
                nm_free_pos_count_list.add(map.get_free_pos(l).size);
            }
            return new NeighborMap(nm_gsizes, nm_free_pos_count_list);
        }

        public ICoordinatorReservationMessage ask_reservation
        (int lvl, zcd.ModRpc.CallerInfo? caller = null)
        throws CoordinatorNodeNotReadyError, CoordinatorInvalidLevelError, CoordinatorSaturatedGnodeError
        {
            if (map == null) throw new CoordinatorNodeNotReadyError.GENERIC("Node not bootstrapped yet.");
            if (lvl <= 0 || lvl > levels) throw new
                    CoordinatorInvalidLevelError.GENERIC(@"CoordinatorManager.ask_reservation: Bad lvl = $(lvl)");
            return service.client.reserve(lvl);
        }
    }

    internal class CoordinatorService : PeerService
    {
        internal const int coordinator_p_id = 1;
        private const int msec_ttl_new_reservation = 60000;
        private const int q_replica_new_reservation = 15;
        public CoordinatorService(int levels, PeersManager peers_manager, CoordinatorManager mgr, int level_new_gnode)
        {
            base(coordinator_p_id, false);
            this.levels = levels;
            this.peers_manager = peers_manager;
            this.mgr = mgr;
            booking_lists = new ArrayList<ArrayList<Booking>>();
            max_elderships = new ArrayList<int>();
            for (int i = 0; i < levels; i++)
            {
                // empty searchable list of bookings
                booking_lists.add(new ArrayList<Booking>((a,b) => a.pos == b.pos));
                max_elderships.add(0);
            }
            this.fkdd = new DatabaseDescriptor(this);
            this.client = new CoordinatorClient(mgr.gsizes, peers_manager, mgr);

            peers_manager.register(this);
            debug("Service Coordinator registered.\n");
            // launch fixed_keys_db_on_startup in a tasklet
            StartFixedKeysDbHandlerTasklet ts = new StartFixedKeysDbHandlerTasklet();
            ts.t = this;
            ts.level_new_gnode = level_new_gnode;
            tasklet.spawn(ts);
        }
        private class StartFixedKeysDbHandlerTasklet : Object, INtkdTaskletSpawnable
        {
            public CoordinatorService t;
            public int level_new_gnode;
            public void * func()
            {
                t.tasklet_start_fixed_keys_db_handler(level_new_gnode); 
                return null;
            }
        }
        private void tasklet_start_fixed_keys_db_handler(int level_new_gnode)
        {
            peers_manager.fixed_keys_db_on_startup(fkdd, coordinator_p_id, level_new_gnode);
        }

        private int levels;
        private PeersManager peers_manager;
        private CoordinatorManager mgr;
        private ArrayList<ArrayList<Booking>> booking_lists;
        private ArrayList<int> max_elderships;
        private DatabaseDescriptor fkdd;
        internal CoordinatorClient client;

        private class DatabaseDescriptor : Object, IDatabaseDescriptor, IFixedKeysDatabaseDescriptor
        {
            private CoordinatorService t;
            public DatabaseDescriptor(CoordinatorService t)
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

            public bool is_valid_key(Object k)
            {
                if (k is CoordinatorKey)
                {
                    int lvl = ((CoordinatorKey)k).lvl;
                    if (lvl >= 1 && lvl <= t.levels) return true;
                }
                return false;
            }

            public Gee.List<int> evaluate_hash_node(Object k)
            {
                assert(k is CoordinatorKey);
                return t.client.perfect_tuple(k);
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
                if (! (rec is CoordinatorRecord)) return false;
                if (((CoordinatorRecord)rec).lvl != ((CoordinatorKey)k).lvl) return false;
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
                ArrayList<Booking> booking_list = new ArrayList<Booking>((a,b) => a.pos == b.pos);
                booking_list.add_all(t.booking_lists[lvl-1]);
                int max_eldership = t.max_elderships[lvl-1];
                CoordinatorRecord ret = new CoordinatorRecord(lvl, booking_list, max_eldership);
                return ret;
            }

            public void set_record_for_key(Object k, Object rec)
            {
                assert(k is CoordinatorKey);
                CoordinatorKey _k = (CoordinatorKey)k;
                assert(is_valid_key(k));
                assert(rec is CoordinatorRecord);
                CoordinatorRecord _rec = (CoordinatorRecord)rec;
                assert(is_valid_record(k, rec));
                int lvl = _k.lvl;
                t.booking_lists[lvl-1] = new ArrayList<Booking>((a,b) => a.pos == b.pos);
                t.booking_lists[lvl-1].add_all(_rec.booking_list);
                t.max_elderships[lvl-1] = _rec.max_eldership;
            }

            public Object get_key_from_request(IPeersRequest r)
            {
                if (r is CoordinatorReplicaRecordRequest)
                {
                    CoordinatorReplicaRecordRequest _r = (CoordinatorReplicaRecordRequest)r;
                    return new CoordinatorKey(_r.record.lvl);
                }
                else if (r is CoordinatorReserveRequest)
                {
                    CoordinatorReserveRequest _r = (CoordinatorReserveRequest)r;
                    return new CoordinatorKey(_r.lvl);
                }
                error(@"The module is asking for a key for request: $(r.get_type().name()).");
            }

            public int get_timeout_exec(IPeersRequest r)
            {
                if (r is CoordinatorReserveRequest)
                {
                    return timeout_exec_for_request(r);
                }
                error(@"The module is asking for a timeout_exec when the request is not a write: $(r.get_type().name()).");
            }

            public bool is_insert_request(IPeersRequest r)
            {
                return false;
            }

            public bool is_read_only_request(IPeersRequest r)
            {
                return false;
            }

            public bool is_update_request(IPeersRequest r)
            {
                if (r is CoordinatorReserveRequest) return true;
                return false;
            }

            public bool is_replica_value_request(IPeersRequest r)
            {
                if (r is CoordinatorReplicaRecordRequest) return true;
                return false;
            }

            public bool is_replica_delete_request(IPeersRequest r)
            {
                return false;
            }

            public IPeersResponse prepare_response_not_found(IPeersRequest r)
            {
                assert_not_reached();
            }

            public IPeersResponse prepare_response_not_free(IPeersRequest r, Object rec)
            {
                assert_not_reached();
            }

            public IPeersResponse execute(IPeersRequest r)
            throws PeersRefuseExecutionError, PeersRedoFromStartError
            {
                if (r is CoordinatorReserveRequest)
                {
                    CoordinatorReserveRequest _r = (CoordinatorReserveRequest)r;
                    CoordinatorReserveResponse resp = t.handle_reserve(_r.lvl);
                    return resp;
                }
                else if (r is CoordinatorReplicaRecordRequest)
                {
                    CoordinatorReplicaRecordRequest _r = (CoordinatorReplicaRecordRequest)r;
                    t.handle_replica_record(_r.record);
                    return new CoordinatorReplicaRecordSuccessResponse();
                }
                if (r == null)
                    warning("DatabaseDescriptor.execute: Not a valid request class: null");
                else
                    warning(@"DatabaseDescriptor.execute: Not a valid request class: $(r.get_type().name())");
                return new CoordinatorUnknownRequestResponse();
            }

            public Gee.List<Object> get_full_key_domain()
            {
                var ret = new ArrayList<Object>();
                for (int i = 1; i <= t.levels; i++) ret.add(new CoordinatorKey(i));
                return ret;
            }

            public Object get_default_record_for_key(Object k)
            {
                assert(is_valid_key(k));
                CoordinatorRecord ret = new CoordinatorRecord(
                            ((CoordinatorKey)k).lvl,
                            new ArrayList<Booking>((a,b) => a.pos == b.pos),
                            0);
                return ret;
            }
        }

        public override IPeersResponse exec
        (IPeersRequest req, Gee.List<int> client_tuple)
        throws PeersRefuseExecutionError, PeersRedoFromStartError
        {
            return peers_manager.fixed_keys_db_on_request(fkdd, req, client_tuple.size);
        }

        private CoordinatorReserveResponse handle_reserve(int lvl)
        {
            print("start handle_reserve\n");
            if (lvl < 1 || lvl > levels)
            {
                return new CoordinatorReserveResponse.error(
                    "CoordinatorInvalidLevelError",
                    "GENERIC",
                    @"Bad value $(lvl) for lvl.");
            }
            // atomic ON
            Gee.List<int> free_pos = mgr.map.get_free_pos(lvl-1);
            if (free_pos.size == 0)
            {
                return new CoordinatorReserveResponse.error(
                    "CoordinatorSaturatedGnodeError",
                    "GENERIC",
                    @"No more space in map.");
            }
            ArrayList<Booking> todel = new ArrayList<Booking>((a,b) => a.pos == b.pos);
            foreach (Booking booking in booking_lists[lvl-1])
            {
                if (booking.ttl.is_expired())
                {
                    todel.add(booking);
                }
            }
            foreach (Booking booking in todel) booking_lists[lvl-1].remove(booking);
            foreach (Booking booking in booking_lists[lvl-1])
            {
                if (booking.pos in free_pos) free_pos.remove(booking.pos);
            }
            if (free_pos.size == 0)
            {
                return new CoordinatorReserveResponse.error(
                    "CoordinatorSaturatedGnodeError",
                    "GENERIC",
                    @"No more space in {map - bookings}.");
            }
            int pos = free_pos[Random.int_range(0, free_pos.size)];
            booking_lists[lvl-1].add(new Booking(pos, msec_ttl_new_reservation));
            // max_eldership[lvl-1] += 1;  do not use += operator, there's a bug in valac
            max_elderships[lvl-1] = max_elderships[lvl-1] + 1;
            CoordinatorReserveResponse ret = new CoordinatorReserveResponse.success(pos, max_elderships[lvl-1]);
            // atomic OFF

            // Perform first two replicas, if possible, before returning success to the query node.
            IPeersContinuation cont;
            CoordinatorKey k = new CoordinatorKey(lvl);
            CoordinatorRecord rec = (CoordinatorRecord)fkdd.get_record_for_key(k);
            bool replica_ret = request_replica_record_first(k, rec, out cont);
            if (replica_ret)
            {
                // one more...
                replica_ret = request_replica_record_once(cont);
                if (replica_ret)
                {
                    // any more in a tasklet
                    request_replica_record_finish(cont);
                }
            }

            print("finish handle_reserve\n");
            return ret;
        }

        private bool request_replica_record_first(CoordinatorKey k, CoordinatorRecord record, out IPeersContinuation cont)
        {
            Gee.List<int> perfect_tuple = client.perfect_tuple(k);
            CoordinatorReplicaRecordRequest r = new CoordinatorReplicaRecordRequest(record);
            int timeout_exec = timeout_exec_for_request(r);
            IPeersResponse resp;
            bool ret = peers_manager.begin_replica
                (q_replica_new_reservation, coordinator_p_id,
                 perfect_tuple, r, timeout_exec, out resp, out cont);
            if (ret)
            {
                if (resp == null)
                    warning("CoordinatorService: sending replica: returned null");
                else if (! (resp is CoordinatorReplicaRecordSuccessResponse))
                    warning(@"CoordinatorService: sending replica: returned unknown class $(resp.get_type().name())");
            }
            return ret;
        }
        private bool request_replica_record_once(IPeersContinuation cont)
        {
            IPeersResponse resp;
            bool ret = peers_manager.next_replica(cont, out resp);
            if (ret)
            {
                if (resp == null)
                    warning("CoordinatorService: sending replica: returned null");
                else if (! (resp is CoordinatorReplicaRecordSuccessResponse))
                    warning(@"CoordinatorService: sending replica: returned unknown class $(resp.get_type().name())");
            }
            return ret;
        }
        private void request_replica_record_finish(IPeersContinuation cont)
        {
            RequestReplicaRecordTasklet ts = new RequestReplicaRecordTasklet();
            ts.t = this;
            ts.cont = cont;
            tasklet.spawn(ts);
        }
        private class RequestReplicaRecordTasklet : Object, INtkdTaskletSpawnable
        {
            public CoordinatorService t;
            public IPeersContinuation cont;
            public void * func()
            {
                t.tasklet_request_replica_record_finish(cont); 
                return null;
            }
        }
        private void tasklet_request_replica_record_finish(IPeersContinuation cont)
        {
            IPeersResponse resp;
            while (peers_manager.next_replica(cont, out resp))
            {
                if (resp == null)
                    warning("CoordinatorService: sending replica: returned null");
                else if (! (resp is CoordinatorReplicaRecordSuccessResponse))
                    warning(@"CoordinatorService: sending replica: returned unknown class $(resp.get_type().name())");
                // nop
            }
        }

        private void handle_replica_record(CoordinatorRecord record)
        {
            fkdd.set_record_for_key(new CoordinatorKey(record.lvl), record);
        }
    }

    internal class CoordinatorClient : PeerClient
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
            uint64 hash = fnv_64(@"$(_k.lvl)_$(_k.lvl)_$(_k.lvl)".data);
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

        public ICoordinatorReservationMessage reserve(int lvl)
        throws CoordinatorSaturatedGnodeError, CoordinatorInvalidLevelError
        {
            if (lvl < 0 || lvl >= mgr.levels) error(@"CoordinatorClient.reserve: Bad lvl = $(lvl)");
            CoordinatorKey k = new CoordinatorKey(lvl);
            CoordinatorReserveRequest r = new CoordinatorReserveRequest(lvl);
            int timeout_exec = timeout_exec_for_request(r);
            IPeersResponse resp;
            Reservation ret;
            try {
                print("start call\n");
                resp = call(k, r, timeout_exec);
                print("finish call\n");
            }
            catch (PeersNoParticipantsInNetworkError e) {
                error(@"CoordinatorClient.reserve($(lvl)): call: got PeersNoParticipantsInNetworkError");
            }
            catch (PeersDatabaseError e) {
                error(@"CoordinatorClient.reserve($(lvl)): call: got PeersDatabaseError");
            }
            if (resp is CoordinatorReserveResponse)
            {
                CoordinatorReserveResponse _resp = (CoordinatorReserveResponse)resp;
                if (_resp.error_domain != null || _resp.error_code != null || _resp.error_message != null)
                {
                    string error_domain_code;
                    string error_msg;
                    if (_resp.error_domain == null || _resp.error_code == null)
                    {
                        error_domain_code = "DeserializeError.GENERIC";
                        error_msg = "There was an error, but its data was incomplete.";
                    }
                    else
                    {
                        error_domain_code = @"$(_resp.error_domain).$(_resp.error_code)";
                        if (_resp.error_message == null) error_msg = "";
                        else error_msg = _resp.error_message;
                    }
                    if (error_domain_code == "CoordinatorSaturatedGnodeError.GENERIC")
                        throw new CoordinatorSaturatedGnodeError.GENERIC(error_msg);
                    if (error_domain_code == "CoordinatorInvalidLevelError.GENERIC")
                        throw new CoordinatorInvalidLevelError.GENERIC(error_msg);
                    string msg = @"CoordinatorClient.reserve($(lvl)): call: returned $(error_domain_code): $(error_msg)";
                    warning(msg);
                    throw new CoordinatorSaturatedGnodeError.GENERIC(msg);
                }
                if (_resp.pos < 0 || _resp.pos > mgr.gsizes[lvl-1])
                {
                    string msg = @"CoordinatorClient.reserve($(lvl)): call: returned incongruent pos $(_resp.pos)";
                    warning(msg);
                    throw new CoordinatorSaturatedGnodeError.GENERIC(msg);
                }
                if (_resp.pos == mgr.pos[lvl-1])
                {
                    string msg = @"CoordinatorClient.reserve($(lvl)): call: returned my same pos $(_resp.pos)";
                    warning(msg);
                    throw new CoordinatorSaturatedGnodeError.GENERIC(msg);
                }
                if (_resp.eldership < 1)
                {
                    string msg = @"CoordinatorClient.reserve($(lvl)): call: " +
                    @"returned an eldership incongruent: $(_resp.eldership)";
                    warning(msg);
                    throw new CoordinatorSaturatedGnodeError.GENERIC(msg);
                }
                ret = new Reservation(
                        mgr.levels,
                        mgr.gsizes,
                        lvl-1, _resp.pos, _resp.eldership,
                        mgr.pos.slice(lvl, mgr.levels),
                        mgr.elderships.slice(lvl, mgr.levels));
            }
            else
            {
                // unexpected class
                if (resp == null)
                    warning(@"CoordinatorClient.reserve: call: Got unexpected null.");
                else
                    warning(@"CoordinatorClient.reserve: call: Got unexpected class $(resp.get_type().name()).");
                throw new CoordinatorSaturatedGnodeError.GENERIC("CoordinatorClient.reserve: call: got unexpected class");
            }
            return ret;
        }
    }
}

