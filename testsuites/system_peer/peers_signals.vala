using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using TaskletSystem;

namespace SystemPeer
{
    void per_identity_peers_failing_arc(IdentityData id, IPeersArc arc)
    {
        PeersArc _arc = (PeersArc)arc;
        IdentityArc ia = _arc.ia;
        NodeID peer_nodeid = ia.peer_nodeid;
        PseudoArc pseudoarc = ia.arc;
        int arc_num = -1;
        for (int i = 0; i < arc_list.size; i++)
        {
            PseudoArc _pseudoarc = arc_list[i];
            if (_pseudoarc == pseudoarc)
            {
                arc_num = i;
                break;
            }
        }
        assert(arc_num >= 0);
        int peer_id = -1;
        for (int i = 0; i < 10; i++)
        {
            NodeID _peer_nodeid = fake_random_nodeid(pseudoarc.peer_pid, i);
            if (_peer_nodeid.equals(peer_nodeid))
            {
                peer_id = i;
                break;
            }
        }
        assert(peer_id >= 0);
        string descr = @"$(arc_num)+$(peer_id)";
        print(@"INFO: Identity #$(id.local_identity_index): arc $(descr) failed; will remove.\n");
        tester_events.add(@"PeersManager:$(id.local_identity_index):Signal:failing_arc:$(descr)");
        HCoord gw = id.my_naddr_get_coord_by_address(ia.peer_naddr_pos);
        if (id.gateways.has_key(gw.lvl))
            if (id.gateways[gw.lvl].has_key(gw.pos))
            id.gateways[gw.lvl][gw.pos].remove(ia);
        id.identity_arcs.remove(ia);
    }
}