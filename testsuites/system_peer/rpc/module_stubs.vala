using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using Netsukuku.Coordinator;
using TaskletSystem;

namespace SystemPeer
{
    class PeersManagerStubHolder : Object, IPeersManagerStub
    {
        public PeersManagerStubHolder.from_arc(IAddressManagerStub addr, IdentityArc ia)
        {
            this.addr = addr;
            this.ia = ia;
            s_positions = null;
        }

        public PeersManagerStubHolder.from_positions(IAddressManagerStub addr, Gee.List<int> positions)
        {
            this.addr = addr;
            this.positions = new ArrayList<int>();
            this.positions.add_all(positions);
            s_positions = "";
            string s_next = "";
            foreach (int p in positions)
            {
                s_positions = @"$(s_positions)$(s_next)$(p)";
                s_next = ",";
            }
            s_positions = @"[$(s_positions)]";
            ia = null;
        }

        private IAddressManagerStub addr;
        public IdentityArc? ia;
        private ArrayList<int> positions;
        private string? s_positions;

        private void log_call(string m_name)
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling $(m_name)");
            if (ia != null) print(@" unicast to nodeid $(ia.peer_nodeid.id).\n");
            else print(@" unicast to position $(s_positions).\n");
        }

        public IPeerParticipantSet ask_participant_maps() throws StubError, DeserializeError
        {
            log_call("ask_participant_maps");
            return addr.peers_manager.ask_participant_maps();
        }

        public void forward_peer_message(IPeerMessage peer_message) throws StubError, DeserializeError
        {
            log_call("forward_peer_message");
            addr.peers_manager.forward_peer_message(peer_message);
        }

        public IPeersRequest get_request(int msg_id, IPeerTupleNode respondant)
        throws PeersUnknownMessageError, PeersInvalidRequest, StubError, DeserializeError
        {
            log_call("get_request");
            return addr.peers_manager.get_request(msg_id, respondant);
        }

        public void give_participant_maps(IPeerParticipantSet maps) throws StubError, DeserializeError
        {
            log_call("give_participant_maps");
            addr.peers_manager.give_participant_maps(maps);
        }

        public void set_failure(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_failure");
            addr.peers_manager.set_failure(msg_id, tuple);
        }

        public void set_missing_optional_maps(int msg_id) throws StubError, DeserializeError
        {
            log_call("set_missing_optional_maps");
            addr.peers_manager.set_missing_optional_maps(msg_id);
        }

        public void set_next_destination(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_next_destination");
            addr.peers_manager.set_next_destination(msg_id, tuple);
        }

        public void set_non_participant(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_non_participant");
            addr.peers_manager.set_non_participant(msg_id, tuple);
        }

        public void set_participant(int p_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_participant");
            addr.peers_manager.set_participant(p_id, tuple);
        }

        public void set_redo_from_start(int msg_id, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            log_call("set_redo_from_start");
            addr.peers_manager.set_redo_from_start(msg_id, respondant);
        }

        public void set_refuse_message(int msg_id, string refuse_message, int e_lvl, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            log_call("set_refuse_message");
            addr.peers_manager.set_refuse_message(msg_id, refuse_message, e_lvl, respondant);
        }

        public void set_response(int msg_id, IPeersResponse response, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            log_call("set_response");
            addr.peers_manager.set_response(msg_id, response, respondant);
        }
    }

    class PeersManagerStubBroadcastHolder : Object, IPeersManagerStub
    {
        public PeersManagerStubBroadcastHolder(Gee.List<IAddressManagerStub> addr_list, int local_identity_index)
        {
            this.addr_list = addr_list;
            this.local_identity_index = local_identity_index;
        }
        private Gee.List<IAddressManagerStub> addr_list;
        private int local_identity_index;

        private void log_call(string m_name)
        {
            print(@"PeersManager: Identity #$(local_identity_index): [$(printabletime())] calling $(m_name) broadcast.\n");
        }

        public IPeerParticipantSet ask_participant_maps() throws StubError, DeserializeError
        {
            error("no broadcast for method ask_participant_maps");
        }

        public void forward_peer_message(IPeerMessage peer_message) throws StubError, DeserializeError
        {
            log_call("forward_peer_message");
            foreach (var addr in addr_list)
            addr.peers_manager.forward_peer_message(peer_message);
        }

        public IPeersRequest get_request(int msg_id, IPeerTupleNode respondant)
        throws PeersUnknownMessageError, PeersInvalidRequest, StubError, DeserializeError
        {
            error("no broadcast for method get_request");
        }

        public void give_participant_maps(IPeerParticipantSet maps) throws StubError, DeserializeError
        {
            log_call("give_participant_maps");
            foreach (var addr in addr_list)
            addr.peers_manager.give_participant_maps(maps);
        }

        public void set_failure(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_failure");
            foreach (var addr in addr_list)
            addr.peers_manager.set_failure(msg_id, tuple);
        }

        public void set_missing_optional_maps(int msg_id) throws StubError, DeserializeError
        {
            log_call("set_missing_optional_maps");
            foreach (var addr in addr_list)
            addr.peers_manager.set_missing_optional_maps(msg_id);
        }

        public void set_next_destination(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_next_destination");
            foreach (var addr in addr_list)
            addr.peers_manager.set_next_destination(msg_id, tuple);
        }

        public void set_non_participant(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_non_participant");
            foreach (var addr in addr_list)
            addr.peers_manager.set_non_participant(msg_id, tuple);
        }

        public void set_participant(int p_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            log_call("set_participant");
            foreach (var addr in addr_list)
            addr.peers_manager.set_participant(p_id, tuple);
        }

        public void set_redo_from_start(int msg_id, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            log_call("set_redo_from_start");
            foreach (var addr in addr_list)
            addr.peers_manager.set_redo_from_start(msg_id, respondant);
        }

        public void set_refuse_message(int msg_id, string refuse_message, int e_lvl, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            log_call("set_refuse_message");
            foreach (var addr in addr_list)
            addr.peers_manager.set_refuse_message(msg_id, refuse_message, e_lvl, respondant);
        }

        public void set_response(int msg_id, IPeersResponse response, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            log_call("set_response");
            foreach (var addr in addr_list)
            addr.peers_manager.set_response(msg_id, response, respondant);
        }
    }

    class PeersManagerStubVoid : Object, IPeersManagerStub
    {
        public IPeerParticipantSet ask_participant_maps() throws StubError, DeserializeError
        {
            assert_not_reached();
        }

        public void forward_peer_message(IPeerMessage peer_message) throws StubError, DeserializeError
        {
        }

        public IPeersRequest get_request(int msg_id, IPeerTupleNode respondant)
        throws PeersUnknownMessageError, PeersInvalidRequest, StubError, DeserializeError
        {
            assert_not_reached();
        }

        public void give_participant_maps(IPeerParticipantSet maps) throws StubError, DeserializeError
        {
        }

        public void set_failure(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
        }

        public void set_missing_optional_maps(int msg_id) throws StubError, DeserializeError
        {
        }

        public void set_next_destination(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
        }

        public void set_non_participant(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
        }

        public void set_participant(int p_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
        }

        public void set_redo_from_start(int msg_id, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
        }

        public void set_refuse_message(int msg_id, string refuse_message, int e_lvl, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
        }

        public void set_response(int msg_id, IPeersResponse response, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
        }
    }

    class CoordinatorManagerStubHolder : Object, ICoordinatorManagerStub
    {
        public CoordinatorManagerStubHolder(IAddressManagerStub addr, IdentityArc ia)
        {
            this.addr = addr;
            this.ia = ia;
        }
        private IAddressManagerStub addr;
        private IdentityArc ia;

        public void execute_prepare_migration(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject prepare_migration_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling ");
            print(@"execute_prepare_migration to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_prepare_migration(tuple, fp_id, propagation_id, lvl, prepare_migration_data);
        }

        public void execute_finish_migration(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject finish_migration_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling ");
            print(@"execute_finish_migration to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_finish_migration(tuple, fp_id, propagation_id, lvl, finish_migration_data);
        }

        public void execute_prepare_enter(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject prepare_enter_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling ");
            print(@"execute_prepare_enter to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_prepare_enter(tuple, fp_id, propagation_id, lvl, prepare_enter_data);
        }

        public void execute_finish_enter(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject finish_enter_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling ");
            print(@"execute_finish_enter to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_finish_enter(tuple, fp_id, propagation_id, lvl, finish_enter_data);
        }

        public void execute_we_have_splitted(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject we_have_splitted_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling ");
            print(@"execute_we_have_splitted to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_we_have_splitted(tuple, fp_id, propagation_id, lvl, we_have_splitted_data);
        }
    }

    class CoordinatorManagerStubVoid : Object, ICoordinatorManagerStub
    {
        public void execute_prepare_migration(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject prepare_migration_data)
        throws StubError, DeserializeError
        {
        }

        public void execute_finish_migration(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject finish_migration_data)
        throws StubError, DeserializeError
        {
        }

        public void execute_prepare_enter(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject prepare_enter_data)
        throws StubError, DeserializeError
        {
        }

        public void execute_finish_enter(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject finish_enter_data)
        throws StubError, DeserializeError
        {
        }

        public void execute_we_have_splitted(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject we_have_splitted_data)
        throws StubError, DeserializeError
        {
        }
    }
}