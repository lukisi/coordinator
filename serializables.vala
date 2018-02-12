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

namespace Netsukuku.Coordinator
{
    internal class SerTimer : Object
    {
        public SerTimer(int msec_ttl)
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

    internal class Booking : Object
    {
        public int reserve_request_id {get; set;}
        public int new_pos {get; set;}
        public int new_eldership {get; set;}
        public SerTimer timeout {get; set;}
    }

    internal class CoordGnodeMemory : Object, Json.Serializable
    {
        public Gee.List<Booking> reserve_list {get; set;}
        public int max_virtual_pos {get; set;}
        public int max_eldership {get; set;}
        public int n_nodes {get; set;} // Logically is a nullable int. It is implemented as -1 => null.
        public SerTimer? n_nodes_timeout {get; set;}
        public Object? hooking_memory {get; set; default=null;}

        public void setnullable_n_nodes(int? x)
        {
            if (x == null) n_nodes = -1;
            else n_nodes = x;
        }
        public int? getnullable_n_nodes()
        {
            if (n_nodes == -1) return null;
            else return n_nodes;
        }

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "reserve_list":
            case "reserve-list":
                try {
                    @value = deserialize_list_booking(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "max_virtual_pos":
            case "max-virtual-pos":
            case "max_eldership":
            case "max-eldership":
            case "n_nodes":
            case "n-nodes":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "n_nodes_timeout":
            case "n-nodes-timeout":
                try {
                    @value = deserialize_nullable_sertimer(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "hooking_memory":
            case "hooking-memory":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
            case "reserve_list":
            case "reserve-list":
                return serialize_list_booking((Gee.List<Booking>)@value);
            case "max_virtual_pos":
            case "max-virtual-pos":
            case "max_eldership":
            case "max-eldership":
            case "n_nodes":
            case "n-nodes":
                return serialize_int((int)@value);
            case "n_nodes_timeout":
            case "n-nodes-timeout":
                return serialize_nullable_sertimer((SerTimer?)@value);
            case "hooking_memory":
            case "hooking-memory":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class NumberOfNodesRequest : Object, IPeersRequest
    {
    }

    internal class NumberOfNodesResponse : Object, IPeersResponse
    {
        public int n_nodes {get; set;}
    }

    internal class EvaluateEnterRequest : Object, Json.Serializable, IPeersRequest
    {
        public int lvl {get; set;}
        public Object evaluate_enter_data {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "lvl":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "evaluate_enter_data":
            case "evaluate-enter-data":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
                return serialize_int((int)@value);
            case "evaluate_enter_data":
            case "evaluate-enter-data":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class EvaluateEnterResponse : Object, Json.Serializable, IPeersResponse
    {
        public Object evaluate_enter_result {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "evaluate_enter_result":
            case "evaluate-enter-result":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
            case "evaluate_enter_result":
            case "evaluate-enter-result":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class BeginEnterRequest : Object, Json.Serializable, IPeersRequest
    {
        public int lvl {get; set;}
        public Object begin_enter_data {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "lvl":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "begin_enter_data":
            case "begin-enter-data":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
                return serialize_int((int)@value);
            case "begin_enter_data":
            case "begin-enter-data":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class BeginEnterResponse : Object, Json.Serializable, IPeersResponse
    {
        public Object begin_enter_result {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "begin_enter_result":
            case "begin-enter-result":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
            case "begin_enter_result":
            case "begin-enter-result":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class CompletedEnterRequest : Object, Json.Serializable, IPeersRequest
    {
        public int lvl {get; set;}
        public Object completed_enter_data {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "lvl":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "completed_enter_data":
            case "completed-enter-data":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
                return serialize_int((int)@value);
            case "completed_enter_data":
            case "completed-enter-data":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class CompletedEnterResponse : Object, Json.Serializable, IPeersResponse
    {
        public Object completed_enter_result {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "completed_enter_result":
            case "completed-enter-result":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
            case "completed_enter_result":
            case "completed-enter-result":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class AbortEnterRequest : Object, Json.Serializable, IPeersRequest
    {
        public int lvl {get; set;}
        public Object abort_enter_data {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "lvl":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "abort_enter_data":
            case "abort-enter-data":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
                return serialize_int((int)@value);
            case "abort_enter_data":
            case "abort-enter-data":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class AbortEnterResponse : Object, Json.Serializable, IPeersResponse
    {
        public Object abort_enter_result {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "abort_enter_result":
            case "abort-enter-result":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
            case "abort_enter_result":
            case "abort-enter-result":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class GetHookingMemoryRequest : Object, IPeersRequest
    {
        public int lvl {get; set;}
    }

    internal class GetHookingMemoryResponse : Object, Json.Serializable, IPeersResponse
    {
        public Object hooking_memory {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "hooking_memory":
            case "hooking-memory":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
            case "hooking_memory":
            case "hooking-memory":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class SetHookingMemoryRequest : Object, Json.Serializable, IPeersRequest
    {
        public int lvl {get; set;}
        public Object hooking_memory {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "lvl":
                try {
                    @value = deserialize_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            case "hooking_memory":
            case "hooking-memory":
                try {
                    @value = deserialize_object(typeof(Object), true, property_node);
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
                return serialize_int((int)@value);
            case "hooking_memory":
            case "hooking-memory":
                return serialize_object((Object?)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal class SetHookingMemoryResponse : Object, IPeersResponse
    {
    }

    internal class ReserveEnterRequest : Object, IPeersRequest
    {
        public int lvl {get; set;}
        public int reserve_request_id {get; set;}
    }

    internal class ReserveEnterResponse : Object, IPeersResponse
    {
        public int new_pos {get; set;}
        public int new_eldership {get; set;}
    }

    internal class DeleteReserveEnterRequest : Object, IPeersRequest
    {
        public int lvl {get; set;}
        public int reserve_request_id {get; set;}
    }

    internal class DeleteReserveEnterResponse : Object, IPeersResponse
    {
    }

    internal class ReplicaRequest : Object, IPeersRequest
    {
        public int lvl {get; set;}
        public CoordGnodeMemory memory {get; set;}
    }

    internal class ReplicaResponse : Object, IPeersResponse
    {
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

    internal Json.Node serialize_object(Object? obj)
    {
        if (obj == null) return new Json.Node(Json.NodeType.NULL);
        Json.Builder b = new Json.Builder();
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
        return b.get_root();
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

    internal Gee.List<Object> deserialize_list_object(Json.Node property_node)
    throws HelperDeserializeError
    {
        ListDeserializer<Object> c = new ListDeserializer<Object>();
        return c.deserialize_list_object(property_node);
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

    internal SerTimer deserialize_sertimer(Json.Node property_node)
    throws HelperDeserializeError
    {
        return (SerTimer)deserialize_object(typeof(SerTimer), false, property_node);
    }

    internal Json.Node serialize_sertimer(SerTimer n)
    {
        return serialize_object(n);
    }

    internal SerTimer? deserialize_nullable_sertimer(Json.Node property_node)
    throws HelperDeserializeError
    {
        return (SerTimer?)deserialize_object(typeof(SerTimer), true, property_node);
    }

    internal Json.Node serialize_nullable_sertimer(SerTimer? n)
    {
        return serialize_object(n);
    }

    internal Gee.List<Booking> deserialize_list_booking(Json.Node property_node)
    throws HelperDeserializeError
    {
        ListDeserializer<Booking> c = new ListDeserializer<Booking>();
        return c.deserialize_list_object(property_node);
    }

    internal Json.Node serialize_list_booking(Gee.List<Booking> lst)
    {
        return serialize_list_object(lst);
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
}
