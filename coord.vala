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

namespace Netsukuku
{
    public errordomain StubNotWorkingError {
        GENERIC
    }

    public interface ICoordinatorMap : Object
    {
        public abstract int i_coordinator_get_levels();
        public abstract int i_coordinator_get_gsize(int lvl);
        public abstract int i_coordinator_get_eldership(int lvl);
        public abstract Gee.List<int> i_coordinator_get_free_pos(int lvl);
    }

    public interface ICoordinatorNeighborMap : Object
    {
        public abstract int i_coordinator_get_levels();
        public abstract int i_coordinator_get_gsize(int lvl);
        public abstract int i_coordinator_get_free_pos_count(int lvl);
    }

    public interface ICoordinatorReservation : Object
    {
        public abstract int i_coordinator_get_reserved_pos();
        public abstract int i_coordinator_get_reserved_lvl();
        public abstract int i_coordinator_get_eldership(int lvl);
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

    internal class CoordinatorRequest : Object, IPeersRequest
    {
        public string name {get; set;}
        public int reserve_lvl {get; set;}
        public int cache_from_lvl {get; set;}
        public int replica_lvl {get; set;}
        public int replica_pos {get; set;}
        public int replica_eldership {get; set;}
        public const string RESERVE = "reserve";
        public const string RETRIEVE_CACHE = "retrieve_cache";
        public const string REPLICA_RESERVE = "replica_reserve";
    }

    internal class CoordinatorReserveResponse : Object, IPeersResponse, Json.Serializable
    {
        public CoordinatorReserveResponse()
        {
            elderships = new ArrayList<int>();
        }

        public string error_domain {get; set; default = null;}
        public string error_code {get; set; default = null;}
        public string error_message {get; set; default = null;}
        public int pos {get; set;}
        public Gee.List<int> elderships {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "error_domain":
            case "error-domain":
            case "error_code":
            case "error-code":
            case "error_message":
            case "error-message":
                try {
                    @value = deserialize_string_maybe(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "pos":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "elderships":
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
            case "error_domain":
            case "error-domain":
            case "error_code":
            case "error-code":
            case "error_message":
            case "error-message":
                return serialize_string_maybe((string)@value);
            case "pos":
                return serialize_int((int)@value);
            case "elderships":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class CoordinatorReplicaReserveResponse : Object, IPeersResponse
    {
        public string error_domain {get; set; default = null;}
        public string error_code {get; set; default = null;}
        public string error_message {get; set; default = null;}
    }

    internal class CoordinatorRetrieveCacheResponse : Object, IPeersResponse, Json.Serializable
    {
        public CoordinatorRetrieveCacheResponse()
        {
            max_eldership = new ArrayList<int>();
            bookings = new ArrayList<ArrayList<Booking>>();
        }

        public string error_domain {get; set; default = null;}
        public string error_code {get; set; default = null;}
        public string error_message {get; set; default = null;}
        public Gee.List<Gee.List<Booking>> bookings {get; set;}
        public Gee.List<int> max_eldership {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "error_domain":
            case "error-domain":
            case "error_code":
            case "error-code":
            case "error_message":
            case "error-message":
                try {
                    @value = deserialize_string_maybe(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "bookings":
                try {
                    @value = deserialize_list_list_booking(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "max_eldership":
            case "max-eldership":
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
            case "error_domain":
            case "error-domain":
            case "error_code":
            case "error-code":
            case "error_message":
            case "error-message":
                return serialize_string_maybe((string)@value);
            case "bookings":
                return serialize_list_list_booking((Gee.List<Gee.List<Booking>>)@value);
            case "max_eldership":
            case "max-eldership":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class NeighborMap : Object, ICoordinatorNeighborMap, ICoordinatorNeighborMapMessage,
                                         zcd.ModRpc.ISerializable, Json.Serializable
    {
        public NeighborMap()
        {
            gsizes = new ArrayList<int>();
            free_pos = new ArrayList<int>();
        }

        public Gee.List<int> gsizes {get; set;}
        public Gee.List<int> free_pos {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "gsizes":
            case "free_pos":
            case "free-pos":
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
            case "free_pos":
            case "free-pos":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }

        public int i_coordinator_get_levels()
        {
            return gsizes.size;
        }

        public int i_coordinator_get_gsize(int lvl)
        {
            return gsizes[lvl];
        }

        public int i_coordinator_get_free_pos_count(int lvl)
        {
            return free_pos[lvl];
        }

        public bool check_deserialization()
        {
            if (gsizes == null) return false;
            if (free_pos == null) return false;
            if (gsizes.size == 0) return false;
            if (gsizes.size != free_pos.size) return false;
            for (int i = 0; i < gsizes.size; i++)
            {
                if (gsizes[i] <= 0) return false;
                if (free_pos[i] < 0) return false;
            }
            return true;
        }
    }

    internal class Reservation : Object, ICoordinatorReservation, ICoordinatorReservationMessage,
                                         zcd.ModRpc.ISerializable, Json.Serializable
    {
        public Reservation(int pos, int lvl, int[] elderships)
        {
            this.pos = pos;
            this.lvl = lvl;
            eldership = new ArrayList<int>();
            eldership.add_all_array(elderships);
        }

        public int pos {get; set;}
        public int lvl {get; set;}
        public Gee.List<int> eldership {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "pos":
            case "lvl":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "eldership":
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
            case "pos":
            case "lvl":
                return serialize_int((int)@value);
            case "eldership":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }

        public int i_coordinator_get_reserved_pos()
        {
            return pos;
        }

        public int i_coordinator_get_reserved_lvl()
        {
            return lvl;
        }

        public int i_coordinator_get_eldership(int l)
        {
            return eldership[l-lvl];
        }

        public bool check_deserialization()
        {
            if (pos < 0) return false;
            if (lvl < 0) return false;
            if (eldership == null) return false;
            if (eldership.size == 0) return false;
            for (int i = 0; i < eldership.size; i++)
            {
                if (eldership[i] < 0) return false;
            }
            return true;
        }
    }

    internal class CoordinatorUnknownRequestResponse : Object, IPeersResponse
    {
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
            typeof(CoordinatorRequest).class_peek();
            typeof(CoordinatorReserveResponse).class_peek();
            typeof(CoordinatorReplicaReserveResponse).class_peek();
            typeof(CoordinatorRetrieveCacheResponse).class_peek();
            typeof(NeighborMap).class_peek();
            typeof(Reservation).class_peek();
            typeof(CoordinatorUnknownRequestResponse).class_peek();
            tasklet = _tasklet;
        }

        private PeersManager peers_manager;
        internal ICoordinatorMap map;
        private CoordinatorService service;

        public CoordinatorManager
            (PeersManager peers_manager,
             ICoordinatorMap map)
        {
            this.peers_manager = peers_manager;
            this.map = map;
            service = new CoordinatorService(map.i_coordinator_get_levels(), peers_manager, this);
            this.peers_manager.register(service);
        }

        public void presence_notified()
        {
            service.presence_notified();
        }

        public ICoordinatorNeighborMap get_neighbor_map
        (Netsukuku.ModRpc.ICoordinatorManagerStub stub)
        throws StubNotWorkingError
        {
            ICoordinatorNeighborMapMessage ret;
            try {
                ret = stub.retrieve_neighbor_map();
            }
            catch (zcd.ModRpc.StubError e) {
                throw new StubNotWorkingError.GENERIC(@"StubError: $(e.message)");
            }
            catch (zcd.ModRpc.DeserializeError e) {
                throw new StubNotWorkingError.GENERIC(@"DeserializeError: $(e.message)");
            }
            if (ret == null)
                throw new StubNotWorkingError.GENERIC(@"Returned null.");
            if (!(ret is ICoordinatorNeighborMap))
                throw new StubNotWorkingError.GENERIC(@"Returned unknown class $(ret.get_type().name())");
            return (ICoordinatorNeighborMap)ret;
        }

        public ICoordinatorReservation get_reservation
        (Netsukuku.ModRpc.ICoordinatorManagerStub stub, int lvl)
        throws StubNotWorkingError, SaturatedGnodeError
        {
            if (lvl <= 0) error(@"CoordinatorManager.get_reservation: Bad lvl = $(lvl)");
            ICoordinatorReservationMessage ret;
            try {
                ret = stub.ask_reservation(lvl);
            }
            catch (zcd.ModRpc.StubError e) {
                throw new StubNotWorkingError.GENERIC(@"StubError: $(e.message)");
            }
            catch (zcd.ModRpc.DeserializeError e) {
                throw new StubNotWorkingError.GENERIC(@"DeserializeError: $(e.message)");
            }
            if (ret == null)
                throw new StubNotWorkingError.GENERIC(@"Returned null.");
            if (!(ret is ICoordinatorReservation))
                throw new StubNotWorkingError.GENERIC(@"Returned unknown class $(ret.get_type().name())");
            return (ICoordinatorReservation)ret;
        }

        /* Remotable methods */

        public ICoordinatorNeighborMapMessage retrieve_neighbor_map
        (zcd.ModRpc.CallerInfo? caller = null)
        {
            NeighborMap ret = new NeighborMap();
            int levels = map.i_coordinator_get_levels();
            ret.gsizes = new ArrayList<int>();
            ret.free_pos = new ArrayList<int>();
            for (int l = 0; l < levels; l++)
            {
                ret.gsizes.add(map.i_coordinator_get_gsize(l));
                ret.free_pos.add(map.i_coordinator_get_free_pos(l).size);
            }
            return ret;
        }

        public ICoordinatorReservationMessage ask_reservation
        (int lvl, zcd.ModRpc.CallerInfo? caller = null)
        throws SaturatedGnodeError
        {
            if (lvl <= 0) error(@"CoordinatorManager.ask_reservation: Bad lvl = $(lvl)");
            ArrayList<int> gsizes = new ArrayList<int>();
            for (int i = 0; i < map.i_coordinator_get_levels(); i++)
                gsizes.add(map.i_coordinator_get_gsize(i));
            var client = new CoordinatorClient(gsizes, peers_manager);
            return client.reserve(lvl);
        }
    }

    internal class CoordinatorService : PeerService
    {
        internal const int coordinator_p_id = 1;
        private const int msec_ttl_new_reservation = 20000;
        private const int q_replica_new_reservation = 15;
        public CoordinatorService(int levels, PeersManager peers_manager, CoordinatorManager mgr)
        {
            base(coordinator_p_id, false);
            this.levels = levels;
            this.peers_manager = peers_manager;
            this.mgr = mgr;
            retrieve_cache_done = false;
            my_presence_should_be_known = false;
            bookings = new ArrayList<ArrayList<Booking>>();
            max_eldership = new ArrayList<int>();
            for (int i = 0; i < levels; i++)
            {
                // empty searchable list of bookings
                bookings.add(new ArrayList<Booking>((a,b) => a.pos == b.pos));
                max_eldership.add(0);
            }
            if (this.peers_manager.level_new_gnode == levels)
            {
                retrieve_cache_done = true;
            }
            else
            {
                RetrieveRecordsTasklet ts = new RetrieveRecordsTasklet();
                ts.t = this;
                ts.lvl = this.peers_manager.level_new_gnode;
                tasklet.spawn(ts);
            }
        }

        private int levels;
        private PeersManager peers_manager;
        private CoordinatorManager mgr;
        private bool retrieve_cache_done;
        private bool my_presence_should_be_known;
        private ArrayList<ArrayList<Booking>> bookings;
        private ArrayList<int> max_eldership;

        private class RetrieveRecordsTasklet : Object, INtkdTaskletSpawnable
        {
            public CoordinatorService t;
            public int lvl;
            public void * func()
            {
                t.retrieve_records(lvl);
                return null;
            }
        }
        private void retrieve_records(int lvl)
        {
            debug(@"CoordinatorService.retrieve_records: start. lvl = $(lvl)");
            CoordinatorRequest r = new CoordinatorRequest();
            r.name = CoordinatorRequest.RETRIEVE_CACHE;
            r.cache_from_lvl = lvl+1;
            IPeersResponse? resp;
            IPeersContinuation? cont;
            bool ret = peers_manager.begin_retrieve_cache(p_id, r, 5000/*msec*/, out resp, out cont);
            if (resp != null && resp is CoordinatorRetrieveCacheResponse)
            {
                CoordinatorRetrieveCacheResponse _resp = (CoordinatorRetrieveCacheResponse)resp;
                if (_resp.error_domain != null || _resp.error_code != null || _resp.error_message != null)
                {
                    string error_domain_code;
                    string error_msg;
                    if (_resp.error_domain == null || _resp.error_code == null || _resp.error_message == null)
                    {
                        error_domain_code = "DeserializeError.GENERIC";
                        error_msg = "There was an error, but its data was incomplete.";
                    }
                    else
                    {
                        error_domain_code = @"$(_resp.error_domain).$(_resp.error_code)";
                        error_msg = _resp.error_message;
                    }
                    warning(@"CoordinatorService.retrieve_records($(lvl)): first step returned $(error_domain_code): $(error_msg)");
                }
                else
                {
                    debug(@"CoordinatorService.retrieve_records($(lvl)): first step returned data.");
                    if (_resp.bookings.size != levels-lvl)
                    {
                        warning(@"CoordinatorService.retrieve_records($(lvl)): returned" +
                        @" $(_resp.bookings.size) higher levels, expected $(levels-lvl).");
                    }
                    else
                    {
                        for (int i = 0; i < _resp.bookings.size; i++)
                        {
                            int j = lvl + i;
                            debug(@"CoordinatorService.retrieve_records($(lvl)): first step: for level $(j), got $(_resp.bookings[i].size) records.");
                            foreach (Booking b in _resp.bookings[i])
                            {
                                if (! (b in bookings[j]))
                                    bookings[j].add(b);
                            }
                            if (_resp.max_eldership[i] > max_eldership[j])
                                max_eldership[j] = _resp.max_eldership[i];
                            debug(@"CoordinatorService.retrieve_records($(lvl)): first step: for level $(j), now we have $(bookings[j].size) records.");
                        }
                    }
                }
            }
            if (ret)
            {
                while (true)
                {
                    ret = peers_manager.next_retrieve_cache(cont, out resp);
                    if (resp != null && resp is CoordinatorRetrieveCacheResponse)
                    {
                        CoordinatorRetrieveCacheResponse _resp = (CoordinatorRetrieveCacheResponse)resp;
                        if (_resp.error_domain != null || _resp.error_code != null || _resp.error_message != null)
                        {
                            string error_domain_code;
                            string error_msg;
                            if (_resp.error_domain == null || _resp.error_code == null || _resp.error_message == null)
                            {
                                error_domain_code = "DeserializeError.GENERIC";
                                error_msg = "There was an error, but its data was incomplete.";
                            }
                            else
                            {
                                error_domain_code = @"$(_resp.error_domain).$(_resp.error_code)";
                                error_msg = _resp.error_message;
                            }
                            warning(@"CoordinatorService.retrieve_records($(lvl)): another step returned $(error_domain_code): $(error_msg)");
                        }
                        else
                        {
                            debug(@"CoordinatorService.retrieve_records($(lvl)): another step returned data.");
                            if (_resp.bookings.size != levels-lvl)
                            {
                                warning(@"CoordinatorService.retrieve_records($(lvl)): returned" +
                                @" $(_resp.bookings.size) higher levels, expected $(levels-lvl).");
                            }
                            else
                            {
                                for (int i = 0; i < _resp.bookings.size; i++)
                                {
                                    int j = lvl + i;
                                    debug(@"CoordinatorService.retrieve_records($(lvl)): another step: for level $(j), got $(_resp.bookings[i].size) records.");
                                    foreach (Booking b in _resp.bookings[i])
                                    {
                                        if (! (b in bookings[j]))
                                            bookings[j].add(b);
                                    }
                                    if (_resp.max_eldership[i] > max_eldership[j])
                                        max_eldership[j] = _resp.max_eldership[i];
                                    debug(@"CoordinatorService.retrieve_records($(lvl)): another step: for level $(j), now we have $(bookings[j].size) records.");
                                }
                            }
                      }
                    }
                    if (!ret) break;
                }
            }
            retrieve_cache_done = true;
        }

        public void presence_notified()
        {
            my_presence_should_be_known = true;
        }

        public override IPeersResponse exec(IPeersRequest req)
        {
            if (req == null || !(req is CoordinatorRequest))
                return new CoordinatorUnknownRequestResponse();
            CoordinatorRequest _req = (CoordinatorRequest)req;
            if (_req.name == CoordinatorRequest.RESERVE)
                return reserve(_req.reserve_lvl);
            if (_req.name == CoordinatorRequest.REPLICA_RESERVE)
                return replica_reserve(_req.replica_lvl, _req.replica_pos, _req.replica_eldership);
            if (_req.name == CoordinatorRequest.RETRIEVE_CACHE)
                return retrieve_cache(_req.cache_from_lvl);
            return new CoordinatorUnknownRequestResponse();
        }

        private CoordinatorReserveResponse reserve(int lvl)
        {
            CoordinatorReserveResponse ret = new CoordinatorReserveResponse();
            if (lvl < 1 || lvl > levels)
            {
                ret.error_domain = "DeserializeError";
                ret.error_code = "GENERIC";
                ret.error_message = @"Bad value $(lvl) for lvl.";
                return ret;
            }
            // atomic ON
            Gee.List<int> free_pos = mgr.map.i_coordinator_get_free_pos(lvl-1);
            if (free_pos.size == 0)
            {
                ret.error_domain = "SaturatedGnodeError";
                ret.error_code = "GENERIC";
                ret.error_message = @"No more space in map.";
                return ret;
            }
            ArrayList<Booking> todel = new ArrayList<Booking>();
            foreach (Booking booking in bookings[lvl-1])
            {
                if (booking.ttl.is_expired())
                {
                    todel.add(booking);
                }
            }
            foreach (Booking booking in todel) bookings[lvl-1].remove(booking);
            foreach (Booking booking in bookings[lvl-1])
            {
                if (booking.pos in free_pos) free_pos.remove(booking.pos);
            }
            if (free_pos.size == 0)
            {
                ret.error_domain = "SaturatedGnodeError";
                ret.error_code = "GENERIC";
                ret.error_message = @"No more space in {map - bookings}.";
                return ret;
            }
            int pos = free_pos[Random.int_range(0, free_pos.size)];
            bookings[lvl-1].add(new Booking(pos, msec_ttl_new_reservation));
            // max_eldership[lvl-1] += 1;  do not use += operator, there's a bug in valac
            max_eldership[lvl-1] = max_eldership[lvl-1] + 1;
            int eldership = max_eldership[lvl-1];
            ret.pos = pos;
            ret.elderships = new ArrayList<int>();
            ret.elderships.add(eldership);
            // atomic OFF
            ArrayList<int> gsizes = new ArrayList<int>();
            for (int i = 0; i < mgr.map.i_coordinator_get_levels(); i++)
                gsizes.add(mgr.map.i_coordinator_get_gsize(i));
            var client = new CoordinatorClient(gsizes, peers_manager);
            var clientkey = new CoordinatorKey(lvl);
            var perfect_tuple = client.perfect_tuple(clientkey);
            var q = q_replica_new_reservation;
            CoordinatorRequest r = new CoordinatorRequest();
            r.name = CoordinatorRequest.REPLICA_RESERVE;
            r.replica_pos = pos;
            r.replica_eldership = eldership;
            r.replica_lvl = lvl;
            IPeersResponse? resp;
            IPeersContinuation? cont;
            bool replica_ret = peers_manager.begin_replica(q, p_id, perfect_tuple, r, 5000/*msec*/, out resp, out cont);
            if (replica_ret)
            {
                if (resp == null)
                    warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned null");
                else if (! (resp is CoordinatorReplicaReserveResponse))
                    warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned unknown class $(resp.get_type().name())");
                else
                {
                    CoordinatorReplicaReserveResponse _resp = (CoordinatorReplicaReserveResponse)resp;
                    if (_resp.error_domain != null || _resp.error_code != null || _resp.error_message != null)
                    {
                        string error_domain_code;
                        string error_msg;
                        if (_resp.error_domain == null || _resp.error_code == null || _resp.error_message == null)
                        {
                            error_domain_code = "DeserializeError.GENERIC";
                            error_msg = "There was an error, but its data was incomplete.";
                        }
                        else
                        {
                            error_domain_code = @"$(_resp.error_domain).$(_resp.error_code)";
                            error_msg = _resp.error_message;
                        }
                        warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned $(error_domain_code): $(error_msg)");
                    }
                    else
                    {
                        debug("CoordinatorService.reserve($(lvl)): sending replica: OK");
                    }
                }
                // one more...
                replica_ret = peers_manager.next_replica(cont, out resp);
                if (replica_ret)
                {
                    if (resp == null)
                        warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned null");
                    else if (! (resp is CoordinatorReplicaReserveResponse))
                        warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned unknown class $(resp.get_type().name())");
                    else
                    {
                        CoordinatorReplicaReserveResponse _resp = (CoordinatorReplicaReserveResponse)resp;
                        if (_resp.error_domain != null || _resp.error_code != null || _resp.error_message != null)
                        {
                            string error_domain_code;
                            string error_msg;
                            if (_resp.error_domain == null || _resp.error_code == null || _resp.error_message == null)
                            {
                                error_domain_code = "DeserializeError.GENERIC";
                                error_msg = "There was an error, but its data was incomplete.";
                            }
                            else
                            {
                                error_domain_code = @"$(_resp.error_domain).$(_resp.error_code)";
                                error_msg = _resp.error_message;
                            }
                            warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned $(error_domain_code): $(error_msg)");
                        }
                        else
                        {
                            debug("CoordinatorService.reserve($(lvl)): sending replica: OK");
                        }
                    }
                    // any more in a tasklet
                    SendReplicasTasklet ts = new SendReplicasTasklet();
                    ts.t = this;
                    ts.lvl = lvl;
                    ts.cont = cont;
                    tasklet.spawn(ts);
                }
            }
            for (int i = lvl; i < levels; i++)
            {
                ret.elderships.add(mgr.map.i_coordinator_get_eldership(i));
            }
            return ret;
        }

        private class SendReplicasTasklet : Object, INtkdTaskletSpawnable
        {
            public CoordinatorService t;
            public int lvl;
            public IPeersContinuation? cont;
            public void * func()
            {
                t.send_replicas(lvl, cont);
                return null;
            }
        }
        private void send_replicas(int lvl, IPeersContinuation? cont)
        {
            IPeersResponse? resp;
            while (true)
            {
                bool replica_ret = peers_manager.next_replica(cont, out resp);
                if (! replica_ret) break;
                if (resp == null)
                    warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned null");
                else if (! (resp is CoordinatorReplicaReserveResponse))
                    warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned unknown class $(resp.get_type().name())");
                else
                {
                    CoordinatorReplicaReserveResponse _resp = (CoordinatorReplicaReserveResponse)resp;
                    if (_resp.error_domain != null || _resp.error_code != null || _resp.error_message != null)
                    {
                        string error_domain_code;
                        string error_msg;
                        if (_resp.error_domain == null || _resp.error_code == null || _resp.error_message == null)
                        {
                            error_domain_code = "DeserializeError.GENERIC";
                            error_msg = "There was an error, but its data was incomplete.";
                        }
                        else
                        {
                            error_domain_code = @"$(_resp.error_domain).$(_resp.error_code)";
                            error_msg = _resp.error_message;
                        }
                        warning(@"CoordinatorService.reserve($(lvl)): sending replica: returned $(error_domain_code): $(error_msg)");
                    }
                    else
                    {
                        debug("CoordinatorService.reserve($(lvl)): sending replica: OK");
                    }
                }
            }
        }

        private CoordinatorReplicaReserveResponse replica_reserve(int lvl, int pos, int eldership)
        {
            CoordinatorReplicaReserveResponse ret = new CoordinatorReplicaReserveResponse();
            if (lvl < 1 || lvl > levels)
            {
                ret.error_domain = "DeserializeError";
                ret.error_code = "GENERIC";
                ret.error_message = @"Bad position ($(lvl-1), $(pos)).";
                return ret;
            }
            if (pos < 0 || pos >= mgr.map.i_coordinator_get_gsize(lvl-1))
            {
                ret.error_domain = "DeserializeError";
                ret.error_code = "GENERIC";
                ret.error_message = @"Bad position ($(lvl-1), $(pos)).";
                return ret;
            }
            // atomic ON
            Booking booking = new Booking(pos, msec_ttl_new_reservation);
            if (! (booking in bookings[lvl-1])) bookings[lvl-1].add(booking);
            if (max_eldership[lvl-1] < eldership) max_eldership[lvl-1] = eldership;
            // atomic OFF
            return ret;
        }

        private CoordinatorRetrieveCacheResponse retrieve_cache(int from_lvl)
        {
            debug(@"CoordinatorService.retrieve_cache: start. from_lvl = $(from_lvl)");
            CoordinatorRetrieveCacheResponse ret = new CoordinatorRetrieveCacheResponse();
            if (from_lvl < 1 || from_lvl > levels)
            {
                ret.error_domain = "DeserializeError";
                ret.error_code = "GENERIC";
                ret.error_message = @"Bad value $(from_lvl) for from_lvl.";
                return ret;
            }
            ret.bookings = new ArrayList<ArrayList<Booking>>();
            ret.max_eldership = new ArrayList<int>();
            for (int i = from_lvl-1; i < levels; i++)
            {
                debug(@"CoordinatorService.retrieve_cache: adding list of bookings from my array at position $(i), there are $(bookings[i].size).");
                var ret_bookings = new ArrayList<Booking>((a,b) => a.pos == b.pos);
                ret_bookings.add_all(bookings[i]);
                ret.bookings.add(ret_bookings);
                ret.max_eldership.add(max_eldership[i]);
            }
            return ret;
        }

        public override bool is_ready()
        {
            return my_presence_should_be_known && retrieve_cache_done;
        }
    }

    internal class CoordinatorClient : PeerClient
    {
        public CoordinatorClient(Gee.List<int> gsizes, PeersManager peers_manager)
        {
            base(CoordinatorService.coordinator_p_id, gsizes, peers_manager);
        }

        protected override uint64 hash_from_key(GLib.Object k, uint64 top)
        {
            error("CoordinatorClient.hash_from_key: should not be used.");
        }

        public override Gee.List<int> perfect_tuple(GLib.Object k)
        {
            if (k is CoordinatorKey)
            {
                int lvl = ((CoordinatorKey)k).lvl;
                ArrayList<int> ret = new ArrayList<int>();
                for (int i = 0; i < lvl; i++) ret.add(0);
                return ret;
            }
            else error("CoordinatorClient.perfect_tuple: bad class for key.");
        }

        public ICoordinatorReservationMessage reserve(int lvl) throws SaturatedGnodeError
        {
            if (lvl <= 0) error(@"CoordinatorClient.reserve: Bad lvl = $(lvl)");
            var clientkey = new CoordinatorKey(lvl);
            IPeersResponse resp;
            while (true)
            {
                CoordinatorRequest req = new CoordinatorRequest();
                req.name = CoordinatorRequest.RESERVE;
                req.reserve_lvl = lvl;
                try {
                    resp = call(clientkey, req, 10000);
                    break;
                }
                catch (PeersNoParticipantsInNetworkError e) {
                    tasklet.ms_wait(1000);
                }
            }
            CoordinatorReserveResponse _resp = (CoordinatorReserveResponse)resp;
            if (_resp.error_domain != null || _resp.error_code != null || _resp.error_message != null)
            {
                string error_domain_code;
                string error_msg;
                if (_resp.error_domain == null || _resp.error_code == null || _resp.error_message == null)
                {
                    error_domain_code = "DeserializeError.GENERIC";
                    error_msg = "There was an error, but its data was incomplete.";
                }
                else
                {
                    error_domain_code = @"$(_resp.error_domain).$(_resp.error_code)";
                    error_msg = _resp.error_message;
                }
                if (error_domain_code == "SaturatedGnodeError.GENERIC")
                    throw new SaturatedGnodeError.GENERIC(error_msg);
                warning(@"CoordinatorClient.reserve($(lvl)): returned $(error_domain_code): $(error_msg)");
                error(@"This should be handled by PeersServices. TODO");
            }
            Reservation ret = new Reservation(_resp.pos, lvl-1, _resp.elderships.to_array());
            return ret;
        }
    }

    internal class CoordinatorKey : Object
    {
        public CoordinatorKey(int lvl)
        {
            if (lvl <= 0) error(@"CoordinatorKey: Bad lvl = $(lvl)");
            this.lvl = lvl;
        }

        public int lvl {get; private set;}
    }
}

