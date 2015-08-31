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

using Netsukuku;
using Netsukuku.ModRpc;
using Gee;

namespace LibCoordInternals
{
    internal errordomain HelperDeserializeError {
        GENERIC
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

    internal string? deserialize_string_maybe(Json.Node property_node)
    throws HelperDeserializeError
    {
        Json.Reader r = new Json.Reader(property_node.copy());
        if (r.get_null_value())
            return null;
        if (!r.is_value())
            throw new HelperDeserializeError.GENERIC("element must be a string");
        if (r.get_value().get_value_type() != typeof(string))
            throw new HelperDeserializeError.GENERIC("element must be a string");
        return r.get_string_value();
    }

    internal Json.Node serialize_string_maybe(string? s)
    {
        if (s == null) return new Json.Node(Json.NodeType.NULL);
        Json.Node ret = new Json.Node(Json.NodeType.VALUE);
        ret.set_string(s);
        return ret;
    }

    internal Json.Node serialize_list_list_booking(Gee.List<Gee.List<Booking>> lst_lst)
    {
        Json.Builder b = new Json.Builder();
        b.begin_array();
        foreach (Gee.List<Booking> lst in lst_lst)
        {
            b.begin_array();
            foreach (Booking obj in lst)
            {
                Json.Node * obj_n = Json.gobject_serialize(obj);
                // json_builder_add_value docs says: The builder will take ownership of the #JsonNode.
                // but the vapi does not specify that the formal parameter is owned.
                // So I try and handle myself the unref of obj_n
                b.add_value(obj_n);
            }
            b.end_array();
        }
        b.end_array();
        return b.get_root();
    }

    internal Gee.List<Gee.List<Booking>> deserialize_list_list_booking(Json.Node property_node)
    throws HelperDeserializeError
    {
        ArrayList<ArrayList<Booking>> ret = new ArrayList<ArrayList<Booking>>();
        Json.Reader r = new Json.Reader(property_node.copy());
        if (r.get_null_value())
            throw new HelperDeserializeError.GENERIC("element is not nullable");
        if (!r.is_array())
            throw new HelperDeserializeError.GENERIC("element must be an array");
        int l = r.count_elements();
        for (int j = 0; j < l; j++)
        {
            r.read_element(j);
            // searchable list of bookings
            ret.add(new ArrayList<Booking>((a,b) => a.pos == b.pos));
            if (r.get_null_value())
                throw new HelperDeserializeError.GENERIC("element is not nullable");
            if (!r.is_array())
                throw new HelperDeserializeError.GENERIC("element must be an array");
            int l2 = r.count_elements();
            for (int j2 = 0; j2 < l2; j2++)
            {
                r.read_element(j2);
                unowned Json.Node p_value = property_node.get_array().get_array_element(j).get_element(j2);
                Json.Node cp_value = p_value.copy();
                Booking booking = (Booking)Json.gobject_deserialize(typeof(Booking), cp_value);
                ret[j].add(booking);
                r.end_element();
            }
            r.end_element();
        }
        return ret;
    }
}
