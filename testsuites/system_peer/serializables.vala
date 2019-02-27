using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using Netsukuku.Coordinator;

namespace SystemPeer
{
    public class IdentityAwareSourceID : Object, ISourceID
    {
        public IdentityAwareSourceID(NodeID id)
        {
            this.id = id;
        }
        public NodeID id {get; set;}
    }

    public class IdentityAwareUnicastID : Object, IUnicastID
    {
        public IdentityAwareUnicastID(NodeID id)
        {
            this.id = id;
        }
        public NodeID id {get; set;}
    }

    public class IdentityAwareBroadcastID : Object, Json.Serializable, IBroadcastID
    {
        public IdentityAwareBroadcastID(Gee.List<NodeID> id_set)
        {
            this.id_set = new ArrayList<NodeID>((a, b) => a.equals(b));
            this.id_set.add_all(id_set);
        }
        public Gee.List<NodeID> id_set {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "id_set":
            case "id-set":
                try {
                    @value = deserialize_list_node_id(property_node);
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
            case "id_set":
            case "id-set":
                return serialize_list_node_id((Gee.List<NodeID>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    public class MainIdentitySourceID : Object, ISourceID
    {
    }

    public class MainIdentityUnicastID : Object, IUnicastID
    {
    }

    public class RoutableSrcNic : Object, Json.Serializable, ISrcNic
    {
        public RoutableSrcNic(Gee.List<int> positions)
        {
            this.positions = new ArrayList<int>();
            this.positions.add_all(positions);
        }
        public Gee.List<int> positions {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "positions":
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
            case "positions":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    public class NeighbourSrcNic : Object, ISrcNic
    {
        public NeighbourSrcNic(string mac)
        {
            this.mac = mac;
        }
        public string mac {get; set;}
    }

    public class SerializableData : Object
    {
        public SerializableData(string content)
        {
            this.content = content;
        }
        public string content {get; set;}
    }


    internal errordomain HelperDeserializeError {
        GENERIC
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

    internal Json.Node serialize_object(Object obj)
    {
        Json.Builder b = new Json.Builder();
        b.begin_object();
        b.set_member_name("typename");
        b.add_string_value(obj.get_type().name());
        b.set_member_name("value");
        b.add_value(Json.gobject_serialize(obj));
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

    internal Json.Node serialize_list_object(Gee.List<Object> lst)
    {
        Json.Builder b = new Json.Builder();
        b.begin_array();
        foreach (Object obj in lst)
        {
            b.add_value(serialize_object(obj));
        }
        b.end_array();
        return b.get_root();
    }

    internal Gee.List<NodeID> deserialize_list_node_id(Json.Node property_node)
    throws HelperDeserializeError
    {
        ListDeserializer<NodeID> c = new ListDeserializer<NodeID>();
        var first_ret = c.deserialize_list_object(property_node);
        // N.B. list of NeighborhoodNodeID must be searchable for the Neighborhood module to work.
        var ret = new ArrayList<NodeID>((a, b) => a.equals(b));
        ret.add_all(first_ret);
        return ret;
    }

    internal Json.Node serialize_list_node_id(Gee.List<NodeID> lst)
    {
        return serialize_list_object(lst);
    }
}