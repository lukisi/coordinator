using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using Netsukuku.Coordinator;
using TaskletSystem;

namespace SystemPeer
{
    class PeersManagerStubHolder : Object, IPeersManagerStub
    {
        public PeersManagerStubHolder(IAddressManagerStub addr, IdentityArc ia)
        {
            this.addr = addr;
            this.ia = ia;
        }
        private IAddressManagerStub addr;
        private IdentityArc ia;

        public IPeerParticipantSet ask_participant_maps() throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"ask_participant_maps to nodeid $(ia.peer_nodeid.id).\n");
            return addr.peers_manager.ask_participant_maps();
        }

        public void forward_peer_message(IPeerMessage peer_message) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"forward_peer_message to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.forward_peer_message(peer_message);
        }

        public IPeersRequest get_request(int msg_id, IPeerTupleNode respondant)
        throws PeersUnknownMessageError, PeersInvalidRequest, StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"get_request to nodeid $(ia.peer_nodeid.id).\n");
            return addr.peers_manager.get_request(msg_id, respondant);
        }

        public void give_participant_maps(IPeerParticipantSet maps) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"give_participant_maps to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.give_participant_maps(maps);
        }

        public void set_failure(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_failure to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.set_failure(msg_id, tuple);
        }

        public void set_missing_optional_maps(int msg_id) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_missing_optional_maps to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.set_missing_optional_maps(msg_id);
        }

        public void set_next_destination(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_next_destination to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.set_next_destination(msg_id, tuple);
        }

        public void set_non_participant(int msg_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_non_participant to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.set_non_participant(msg_id, tuple);
        }

        public void set_participant(int p_id, IPeerTupleGNode tuple) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_participant to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.set_participant(p_id, tuple);
        }

        public void set_redo_from_start(int msg_id, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_redo_from_start to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.set_redo_from_start(msg_id, respondant);
        }

        public void set_refuse_message(int msg_id, string refuse_message, int e_lvl, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_refuse_message to nodeid $(ia.peer_nodeid.id).\n");
            addr.peers_manager.set_refuse_message(msg_id, refuse_message, e_lvl, respondant);
        }

        public void set_response(int msg_id, IPeersResponse response, IPeerTupleNode respondant) throws StubError, DeserializeError
        {
            print(@"PeersManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"set_response to nodeid $(ia.peer_nodeid.id).\n");
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
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"execute_prepare_migration to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_prepare_migration(tuple, fp_id, propagation_id, lvl, prepare_migration_data);
        }

        public void execute_finish_migration(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject finish_migration_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"execute_finish_migration to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_finish_migration(tuple, fp_id, propagation_id, lvl, finish_migration_data);
        }

        public void execute_prepare_enter(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject prepare_enter_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"execute_prepare_enter to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_prepare_enter(tuple, fp_id, propagation_id, lvl, prepare_enter_data);
        }

        public void execute_finish_enter(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject finish_enter_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
            print(@"execute_finish_enter to nodeid $(ia.peer_nodeid.id).\n");
            addr.coordinator_manager.execute_finish_enter(tuple, fp_id, propagation_id, lvl, finish_enter_data);
        }

        public void execute_we_have_splitted(ICoordTupleGNode tuple, int64 fp_id, int propagation_id, int lvl, ICoordObject we_have_splitted_data)
        throws StubError, DeserializeError
        {
            print(@"CoordinatorManager: Identity #$(ia.identity_data.local_identity_index): [$(printabletime())] calling unicast ");
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