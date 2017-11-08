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

namespace Netsukuku.Coordinator
{
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

        public unowned GLib.ParamSpec? find_property
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

    internal class NeighborMap : Object, ICoordinatorNeighborMap, ICoordinatorNeighborMapMessage,
                                         ISerializable, Json.Serializable
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

        public unowned GLib.ParamSpec? find_property
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
                                         ISerializable, Json.Serializable
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

        public unowned GLib.ParamSpec? find_property
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

    internal errordomain HelperDeserializeError {
        GENERIC
    }

    internal Object? deserialize_object(Type expected_type, bool nullable, Json.Node property_node)
    throws HelperDeserializeError
    {
        Json.Reader r = new Json.Reader(property_node.copy());
        if (r.get_null_value())
        {
            if (!nullable)
                throw new HelperDeserializeError.GENERIC("element is not nullable");
            return null;
        }
        if (!r.is_object())
            throw new HelperDeserializeError.GENERIC("element must be an object");
        string typename;
        if (!r.read_member("typename"))
            throw new HelperDeserializeError.GENERIC("element must have typename");
        if (!r.is_value())
            throw new HelperDeserializeError.GENERIC("typename must be a string");
        if (r.get_value().get_value_type() != typeof(string))
            throw new HelperDeserializeError.GENERIC("typename must be a string");
        typename = r.get_string_value();
        r.end_member();
        Type type = Type.from_name(typename);
        if (type == 0)
            throw new HelperDeserializeError.GENERIC(@"typename '$(typename)' unknown class");
        if (!type.is_a(expected_type))
            throw new HelperDeserializeError.GENERIC(@"typename '$(typename)' is not a '$(expected_type.name())'");
        if (!r.read_member("value"))
            throw new HelperDeserializeError.GENERIC("element must have value");
        r.end_member();
        unowned Json.Node p_value = property_node.get_object().get_member("value");
        Json.Node cp_value = p_value.copy();
        return Json.gobject_deserialize(type, cp_value);
    }

    internal class ListDeserializer<T> : Object
    {
        internal Gee.List<T> deserialize_list_object(Json.Node property_node)
        throws HelperDeserializeError
        {
            ArrayList<T> ret = new ArrayList<T>();
            Json.Reader r = new Json.Reader(property_node.copy());
            if (r.get_null_value())
                throw new HelperDeserializeError.GENERIC("element is not nullable");
            if (!r.is_array())
                throw new HelperDeserializeError.GENERIC("element must be an array");
            int l = r.count_elements();
            for (uint j = 0; j < l; j++)
            {
                unowned Json.Node p_value = property_node.get_array().get_element(j);
                Json.Node cp_value = p_value.copy();
                ret.add(deserialize_object(typeof(T), false, cp_value));
            }
            return ret;
        }
    }

    internal Json.Node serialize_list_object(Gee.List<Object> lst)
    {
        Json.Builder b = new Json.Builder();
        b.begin_array();
        foreach (Object obj in lst)
        {
            b.begin_object();
            b.set_member_name("typename");
            b.add_string_value(obj.get_type().name());
            b.set_member_name("value");
            Json.Node * obj_n = Json.gobject_serialize(obj);
            // json_builder_add_value docs says: The builder will take ownership of the #JsonNode.
            // but the vapi does not specify that the formal parameter is owned.
            // So I try and handle myself the unref of obj_n
            b.add_value(obj_n);
            b.end_object();
        }
        b.end_array();
        return b.get_root();
    }

    internal int deserialize_int(Json.Node property_node)
    throws HelperDeserializeError
    {
        Json.Reader r = new Json.Reader(property_node.copy());
        if (r.get_null_value())
            throw new HelperDeserializeError.GENERIC("element is not nullable");
        if (!r.is_value())
            throw new HelperDeserializeError.GENERIC("element must be a int");
        if (r.get_value().get_value_type() != typeof(int64))
            throw new HelperDeserializeError.GENERIC("element must be a int");
        int64 val = r.get_int_value();
        if (val > int.MAX || val < int.MIN)
            throw new HelperDeserializeError.GENERIC("element overflows size of int");
        return (int)val;
    }

    internal Json.Node serialize_int(int i)
    {
        Json.Node ret = new Json.Node(Json.NodeType.VALUE);
        ret.set_int(i);
        return ret;
    }

    internal Gee.List<int> deserialize_list_int(Json.Node property_node)
    throws HelperDeserializeError
    {
        ArrayList<int> ret = new ArrayList<int>();
        Json.Reader r = new Json.Reader(property_node.copy());
        if (r.get_null_value())
            throw new HelperDeserializeError.GENERIC("element is not nullable");
        if (!r.is_array())
            throw new HelperDeserializeError.GENERIC("element must be an array");
        int l = r.count_elements();
        for (int j = 0; j < l; j++)
        {
            r.read_element(j);
            if (r.get_null_value())
                throw new HelperDeserializeError.GENERIC("element is not nullable");
            if (!r.is_value())
                throw new HelperDeserializeError.GENERIC("element must be a int");
            if (r.get_value().get_value_type() != typeof(int64))
                throw new HelperDeserializeError.GENERIC("element must be a int");
            int64 val = r.get_int_value();
            if (val > int.MAX || val < int.MIN)
                throw new HelperDeserializeError.GENERIC("element overflows size of int");
            ret.add((int)val);
            r.end_element();
        }
        return ret;
    }

    internal Json.Node serialize_list_int(Gee.List<int> lst)
    {
        Json.Builder b = new Json.Builder();
        b.begin_array();
        foreach (int i in lst)
        {
            b.add_int_value(i);
        }
        b.end_array();
        return b.get_root();
    }

    internal Gee.List<Booking> deserialize_list_booking(Json.Node property_node)
    throws HelperDeserializeError
    {
        ListDeserializer<Booking> c = new ListDeserializer<Booking>();
        var first_ret = c.deserialize_list_object(property_node);
        // List of Booking must be searchable.
        var ret = new ArrayList<Booking>(/*equal_func*/(a,b) => a.pos == b.pos);
        ret.add_all(first_ret);
        return ret;
    }

    internal Json.Node serialize_list_booking(Gee.List<Booking> lst)
    {
        return serialize_list_object(lst);
    }
}
