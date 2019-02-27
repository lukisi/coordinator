using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using Netsukuku.Coordinator;
using TaskletSystem;

namespace SystemPeer
{
    class FakeHookingManager : Object
    {
        public FakeHookingManager(int local_identity_index)
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

        public Object evaluate_enter(Object evaluate_enter_data, Gee.List<int> client_address)
        {
            return pretend_do_something("evaluate_enter", levels, evaluate_enter_data, client_address);
        }

        public Object begin_enter(int lvl, Object begin_enter_data, Gee.List<int> client_address)
        {
            return pretend_do_something("begin_enter", lvl, begin_enter_data, client_address);
        }

        public Object completed_enter(int lvl, Object completed_enter_data, Gee.List<int> client_address)
        {
            return pretend_do_something("completed_enter", lvl, completed_enter_data, client_address);
        }

        public Object abort_enter(int lvl, Object abort_enter_data, Gee.List<int> client_address)
        {
            return pretend_do_something("abort_enter", lvl, abort_enter_data, client_address);
        }

        private Object pretend_do_something(string m_name, int lvl, Object something_data, Gee.List<int> client_address)
        {
            string content = json_string_object(something_data);
            if (something_data is SerializableData)
                content = ((SerializableData)something_data).content;
            print(@"FakeHooking: Identity #$(local_identity_index): executing $(m_name) at level $(lvl)\n");
            print(@"             on data '$(content)'\n");
            string s_client_address = "";
            string s_next = "";
            foreach (int p in client_address)
            {
                s_client_address = @"$(s_client_address)$(s_next)$(p)";
                s_next = ",";
            }
            print(@"             for client [$(s_client_address)].\n");
            tester_events.add(@"FakeHooking:$(local_identity_index):$(m_name):from[$(s_client_address)]");
            return new SerializableData(@"Result processing: $(content)");
        }

        public void prepare_migration(int lvl, Object prepare_migration_data)
        {
            pretend_propagate_something("prepare_migration", lvl, prepare_migration_data);
        }

        public void finish_migration(int lvl, Object finish_migration_data)
        {
            pretend_propagate_something("finish_migration", lvl, finish_migration_data);
        }

        public void prepare_enter(int lvl, Object prepare_enter_data)
        {
            pretend_propagate_something("prepare_enter", lvl, prepare_enter_data);
        }

        public void finish_enter(int lvl, Object finish_enter_data)
        {
            pretend_propagate_something("finish_enter", lvl, finish_enter_data);
        }

        private void pretend_propagate_something(string m_name, int lvl, Object something_data)
        {
            string content = json_string_object(something_data);
            if (something_data is SerializableData)
                content = ((SerializableData)something_data).content;
            print(@"FakeHooking: Identity #$(local_identity_index): propagating $(m_name) at level $(lvl)\n");
            print(@"             on data '$(content)'.\n");
            tester_events.add(@"FakeHooking:$(local_identity_index):$(m_name)");
        }
    }
}