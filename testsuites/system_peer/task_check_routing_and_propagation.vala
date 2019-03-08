using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using Netsukuku.Coordinator;
using TaskletSystem;

namespace SystemPeer
{
    bool schedule_task_check_routing_and_propagation(string task)
    {
        if (task.has_prefix("check_routing_and_propagation,"))
        {
            string remain = task.substring("check_routing_and_propagation,".length);
            string[] args = remain.split(",");
            if (args.length != 1) error("bad args num in task 'check_routing_and_propagation'");
            int64 ms_wait;
            if (! int64.try_parse(args[0], out ms_wait)) error("bad args ms_wait in task 'check_routing_and_propagation'");
            print(@"INFO: in $(ms_wait) ms will do check routing_and_propagation for pid #$(pid).\n");
            CheckRoutingAndPropagationTasklet s = new CheckRoutingAndPropagationTasklet(
                (int)ms_wait);
            tasklet.spawn(s);
            return true;
        }
        else return false;
    }

    class CheckRoutingAndPropagationTasklet : Object, ITaskletSpawnable
    {
        public CheckRoutingAndPropagationTasklet(
            int ms_wait)
        {
            this.ms_wait = ms_wait;
        }
        private int ms_wait;

        public void * func()
        {
            tasklet.ms_wait(ms_wait);

            print(@"Doing check routing_and_propagation for node $(pid).\n");

            if (pid == 100)
            {
                /*
                PeersManagerStubHolder.from_positions:set_response:[2,3,1]
                PeersManagerStubHolder.from_positions:set_response:[1,3,1]
                PeersManagerStubHolder.from_positions:set_response:[2,0,1]
                PeersManagerStubHolder.from_positions:set_response:[1,0,1]
                */
                bool sent_answer_to_2_3_1 = false;
                bool sent_answer_to_1_3_1 = false;
                bool sent_answer_to_2_0_1 = false;
                bool sent_answer_to_1_0_1 = false;
                for (int i = 0; i < tester_events.size; i++)
                {
                    if ("PeersManagerStubHolder.from_positions:set_response:[2,3,1]" in tester_events[i]) sent_answer_to_2_3_1 = true;
                    if ("PeersManagerStubHolder.from_positions:set_response:[1,3,1]" in tester_events[i]) sent_answer_to_1_3_1 = true;
                    if ("PeersManagerStubHolder.from_positions:set_response:[2,0,1]" in tester_events[i]) sent_answer_to_2_0_1 = true;
                    if ("PeersManagerStubHolder.from_positions:set_response:[1,0,1]" in tester_events[i]) sent_answer_to_1_0_1 = true;
                }
                assert(sent_answer_to_2_3_1);
                assert(sent_answer_to_1_3_1);
                assert(sent_answer_to_2_0_1);
                assert(sent_answer_to_1_0_1);
            }
            else if (pid == 101)
            {
                /*
                FakeHooking:1:prepare_enter
                FakeHooking:1:finish_enter
                */
                int index_1_prepare = -1;
                int index_1_finish = -1;
                for (int i = 0; i < tester_events.size; i++)
                {
                    if ("FakeHooking:1:prepare_enter" in tester_events[i]) index_1_prepare = i;
                    if ("FakeHooking:1:finish_enter" in tester_events[i]) index_1_finish = i;
                }
                assert(index_1_prepare >= 0);
                assert(index_1_finish > index_1_prepare);
            }

            return null;
        }
    }
}