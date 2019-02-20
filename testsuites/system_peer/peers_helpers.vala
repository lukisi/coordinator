using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using TaskletSystem;

namespace SystemPeer
{
    class PeersMapPaths : Object, IPeersMapPaths
    {
        public PeersMapPaths(int local_identity_index)
        {
            this.local_identity_index = local_identity_index;
        }
        private int local_identity_index;
        private IdentityData? _identity_data;
        public IdentityData identity_data {
            get {
                _identity_data = find_local_identity_by_index(local_identity_index);
                if (_identity_data == null) tasklet.exit_tasklet();
                return _identity_data;
            }
        }

        public int i_peers_get_levels()
        {
            return levels;
        }

        public int i_peers_get_gsize(int level)
        {
            return gsizes[level];
        }

        public int i_peers_get_my_pos(int level)
        {
            return identity_data.my_naddr_pos[level];
        }

        public int i_peers_get_nodes_in_my_group(int level)
        {
            // just an estimation, not that important if less than 50
            return 10;
        }

        public bool i_peers_exists(int level, int pos)
        {
            //public HashMap<int,HashMap<int,ArrayList<IdentityArc>>> gateways;
            assert(identity_data.gateways.has_key(level));
            if (identity_data.gateways[level].has_key(pos))
                if (identity_data.gateways[level][pos].size > 0)
                return true;
            return false;
        }

        public IPeersManagerStub i_peers_gateway(int level, int pos, CallerInfo? received_from = null, IPeersManagerStub? failed = null)
        throws PeersNonexistentDestinationError
        {
            // If there is a (previous) failed stub, remove the physical arc it was based on.
            if (failed != null)
            {
                IdentityArc ia = ((PeersManagerStubHolder)failed).ia;
                assert(identity_data.gateways.has_key(level));
                if (identity_data.gateways[level].has_key(pos))
                    identity_data.gateways[level][pos].remove(ia);
            }
            // Search a gateway to reach (level, pos) excluding received_from
            NodeID? received_from_nodeid = null;
            if (received_from != null)
            {
                IdentityArc? caller_ia = skeleton_factory.from_caller_get_identityarc(received_from, identity_data);
                if (caller_ia != null) received_from_nodeid = caller_ia.peer_nodeid;
            }
            ArrayList<IdentityArc> available_gw = new ArrayList<IdentityArc>();
            assert(identity_data.gateways.has_key(level));
            if (identity_data.gateways[level].has_key(pos))
                available_gw.add_all(identity_data.gateways[level][pos]);
            while (! available_gw.is_empty)
            {
                IdentityArc gw = available_gw[0];
                NodeID gw_nodeid = gw.peer_nodeid;
                if (received_from_nodeid != null && received_from_nodeid.equals(gw_nodeid))
                {
                    available_gw.remove_at(0);
                    continue;
                }
                // found a gateway, excluding received_from
                break;
            }
            if (available_gw.is_empty) throw new PeersNonexistentDestinationError.GENERIC("No more paths");
            // Note: currently the module PeerServices handles this exception and does not use the message in any way.
            IdentityArc gw_ia = available_gw[0];
            IAddressManagerStub addrstub = stub_factory.get_stub_identity_aware_unicast_from_ia(gw_ia, false);
            PeersManagerStubHolder ret = new PeersManagerStubHolder.from_arc(addrstub, gw_ia);
            return ret;
        }

        public IPeersManagerStub? i_peers_neighbor_at_level(int level, IPeersManagerStub? failed = null)
        {
            // If there is a (previous) failed stub, remove the physical arc it was based on.
            if (failed != null)
            {
                IdentityArc ia = ((PeersManagerStubHolder)failed).ia;
                HCoord gw = identity_data.my_naddr_get_coord_by_address(ia.peer_naddr_pos);
                assert(gw.lvl == level);
                assert(identity_data.gateways.has_key(level));
                if (identity_data.gateways[level].has_key(gw.pos))
                    identity_data.gateways[level][gw.pos].remove(ia);
            }
            IPeersManagerStub? ret = null;
            foreach (IdentityArc ia in identity_data.identity_arcs) if (ia.peer_naddr_pos != null)
            {
                HCoord gw = identity_data.my_naddr_get_coord_by_address(ia.peer_naddr_pos);
                if (gw.lvl == level)
                {
                    IAddressManagerStub addrstub = stub_factory.get_stub_identity_aware_unicast_from_ia(ia, true);
                    ret = new PeersManagerStubHolder.from_arc(addrstub, ia);
                    break;
                }
            }
            return ret;
        }
    }

    class PeersBackStubFactory : Object, IPeersBackStubFactory
    {
        public PeersBackStubFactory(int local_identity_index)
        {
            this.local_identity_index = local_identity_index;
        }
        private int local_identity_index;
        private IdentityData? _identity_data;
        public IdentityData identity_data {
            get {
                _identity_data = find_local_identity_by_index(local_identity_index);
                if (_identity_data == null) tasklet.exit_tasklet();
                return _identity_data;
            }
        }

        public IPeersManagerStub i_peers_get_tcp_inside(Gee.List<int> positions)
        {
            IAddressManagerStub addrstub = stub_factory.get_stub_main_identity_unicast_inside_gnode(positions);
            PeersManagerStubHolder ret = new PeersManagerStubHolder.from_positions(addrstub, positions);
            return ret;
        }
    }

    class PeersNeighborsFactory : Object, IPeersNeighborsFactory
    {
        public PeersNeighborsFactory(int local_identity_index)
        {
            this.local_identity_index = local_identity_index;
        }
        private int local_identity_index;
        private IdentityData? _identity_data;
        public IdentityData identity_data {
            get {
                _identity_data = find_local_identity_by_index(local_identity_index);
                if (_identity_data == null) tasklet.exit_tasklet();
                return _identity_data;
            }
        }

        public IPeersManagerStub i_peers_get_broadcast(IPeersMissingArcHandler missing_handler)
        {
            ArrayList<NodeID> broadcast_node_id_set = new ArrayList<NodeID>();
            foreach (IdentityArc ia in identity_data.identity_arcs)
            {
                // assume it is on my network?
                broadcast_node_id_set.add(ia.peer_nodeid);
            }
            if(broadcast_node_id_set.is_empty) return new PeersManagerStubVoid();
            Gee.List<IAddressManagerStub> addr_list = new ArrayList<IAddressManagerStub>();
            foreach (string my_dev in pseudonic_map.keys)
            {
                MissingArcHandlerForPeers identity_missing_handler =
                    new MissingArcHandlerForPeers(missing_handler);
                IAddressManagerStub addrstub = stub_factory.get_stub_identity_aware_broadcast(
                    my_dev,
                    identity_data,
                    broadcast_node_id_set,
                    identity_missing_handler);
                addr_list.add(addrstub);
            }
            PeersManagerStubBroadcastHolder ret = new PeersManagerStubBroadcastHolder(addr_list, identity_data.local_identity_index);
            return ret;
        }

        public IPeersManagerStub i_peers_get_tcp(IPeersArc arc)
        {
            IdentityArc ia = ((PeersArc)arc).ia;
            IAddressManagerStub addrstub = stub_factory.get_stub_identity_aware_unicast_from_ia(ia, true);
            PeersManagerStubHolder ret = new PeersManagerStubHolder.from_arc(addrstub, ia);
            return ret;
        }
    }

    class MissingArcHandlerForPeers : Object, IIdentityAwareMissingArcHandler
    {
        public MissingArcHandlerForPeers(IPeersMissingArcHandler peers_missing)
        {
            this.peers_missing = peers_missing;
        }
        private IPeersMissingArcHandler peers_missing;

        public void missing(IdentityData identity_data, IdentityArc identity_arc)
        {
            // assume it is on my network?
            PeersArc peers_arc = new PeersArc(identity_data.local_identity_index, identity_arc);
            peers_missing.i_peers_missing(peers_arc);
        }
    }

    class PeersArc : Object, IPeersArc
    {
        public PeersArc(int local_identity_index, IdentityArc ia)
        {
            this.local_identity_index = local_identity_index;
            this._ia = ia;
        }
        private int local_identity_index;
        private IdentityData? _identity_data;
        public IdentityData identity_data {
            get {
                _identity_data = find_local_identity_by_index(local_identity_index);
                if (_identity_data == null) tasklet.exit_tasklet();
                return _identity_data;
            }
        }
        public IdentityArc ia {
            get {
                _identity_data = find_local_identity_by_index(local_identity_index);
                if (_identity_data == null) tasklet.exit_tasklet();
                return _ia;
            }
        }

        public weak IdentityArc _ia;
    }
}