using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using Netsukuku.Coordinator;
using TaskletSystem;

namespace SystemPeer
{
    class CoordinatorEvaluateEnterHandler : Object, IEvaluateEnterHandler
    {
        public CoordinatorEvaluateEnterHandler(int local_identity_index)
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

        public Object evaluate_enter(int lvl, Object evaluate_enter_data, Gee.List<int> client_address)
        throws HandlingImpossibleError
        {
            error("not implemented yet");
        }
    }

    class CoordinatorBeginEnterHandler : Object, IBeginEnterHandler
    {
        public CoordinatorBeginEnterHandler(int local_identity_index)
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

        public Object begin_enter(int lvl, Object begin_enter_data, Gee.List<int> client_address)
        throws HandlingImpossibleError
        {
            error("not implemented yet");
        }
    }

    class CoordinatorCompletedEnterHandler : Object, ICompletedEnterHandler
    {
        public CoordinatorCompletedEnterHandler(int local_identity_index)
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

        public Object completed_enter(int lvl, Object completed_enter_data, Gee.List<int> client_address)
        throws HandlingImpossibleError
        {
            error("not implemented yet");
        }
    }

    class CoordinatorAbortEnterHandler : Object, IAbortEnterHandler
    {
        public CoordinatorAbortEnterHandler(int local_identity_index)
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

        public Object abort_enter(int lvl, Object abort_enter_data, Gee.List<int> client_address)
        throws HandlingImpossibleError
        {
            error("not implemented yet");
        }
    }

    class CoordinatorPropagationHandler : Object, IPropagationHandler
    {
        public CoordinatorPropagationHandler(int local_identity_index)
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

        public void prepare_migration(int lvl, Object prepare_migration_data)
        {
            error("not implemented yet");
        }

        public void finish_migration(int lvl, Object finish_migration_data)
        {
            error("not implemented yet");
        }

        public void prepare_enter(int lvl, Object prepare_enter_data)
        {
            error("not implemented yet");
        }

        public void finish_enter(int lvl, Object finish_enter_data)
        {
            error("not implemented yet");
        }

        public void we_have_splitted(int lvl, Object we_have_splitted_data)
        {
            error("not implemented yet");
        }
    }

    class CoordinatorMap : Object, ICoordinatorMap
    {
        public CoordinatorMap(int local_identity_index)
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

        public int get_my_pos(int lvl)
        {
            error("not implemented yet");
        }

        public bool can_reserve(int lvl)
        {
            if (/*subnetlevel*/ 0 >= lvl) return false;
            if (lvl > levels) return false;
            return true;
        }

        public Gee.List<int> get_free_pos(int lvl)
        {
            error("not implemented yet");
        }

        public int get_n_nodes()
        {
            error("not implemented yet");
        }

        public int64 get_fp_id(int lvl)
        {
            error("not implemented yet");
        }
    }

    class CoordinatorStubFactory : Object, IStubFactory
    {
        public CoordinatorStubFactory(int local_identity_index)
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

        public ICoordinatorManagerStub get_stub_for_all_neighbors()
        {
            ArrayList<NodeID> broadcast_node_id_set = new ArrayList<NodeID>();
            foreach (IdentityArc ia in identity_data.identity_arcs)
            {
                // assume it is on my network?
                broadcast_node_id_set.add(ia.peer_nodeid);
            }
            if(broadcast_node_id_set.is_empty) return new CoordinatorManagerStubVoid();
            Gee.List<IAddressManagerStub> addr_list = new ArrayList<IAddressManagerStub>();
            foreach (string my_dev in pseudonic_map.keys)
            {
                IAddressManagerStub addrstub = stub_factory.get_stub_identity_aware_broadcast(
                    my_dev,
                    identity_data,
                    broadcast_node_id_set,
                    null);
                addr_list.add(addrstub);
            }
            return new CoordinatorManagerStubBroadcastHolder(addr_list, identity_data.local_identity_index);
        }

        public Gee.List<ICoordinatorManagerStub> get_stub_for_each_neighbor()
        {
            ArrayList<ICoordinatorManagerStub> ret = new ArrayList<ICoordinatorManagerStub>();
            foreach (IdentityArc ia in identity_data.identity_arcs)
            {
                // assume it is on my network?
                IAddressManagerStub addrstub = stub_factory.get_stub_identity_aware_unicast_from_ia(ia, false);
                ret.add(new CoordinatorManagerStubHolder(addrstub, ia));
            }
            return ret;
        }
    }
}