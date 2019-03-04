using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using Netsukuku.Coordinator;
using TaskletSystem;

namespace SystemPeer
{
    bool schedule_task_check_get_n_nodes(string task)
    {
        if (task.has_prefix("check_get_n_nodes,"))
        {
            string remain = task.substring("check_get_n_nodes,".length);
            string[] args = remain.split(",");
            if (args.length != 1) error("bad args num in task 'check_get_n_nodes'");
            int64 ms_wait;
            if (! int64.try_parse(args[0], out ms_wait)) error("bad args ms_wait in task 'check_get_n_nodes'");
            print(@"INFO: in $(ms_wait) ms will do check get_n_nodes for pid #$(pid).\n");
            CheckGetNnodesTasklet s = new CheckGetNnodesTasklet(
                (int)ms_wait);
            tasklet.spawn(s);
            return true;
        }
        else return false;
    }

    class CheckGetNnodesTasklet : Object, ITaskletSpawnable
    {
        public CheckGetNnodesTasklet(
            int ms_wait)
        {
            this.ms_wait = ms_wait;
        }
        private int ms_wait;

        public void * func()
        {
            tasklet.ms_wait(ms_wait);

            print(@"Doing check get_n_nodes for node $(pid).\n");

            if (pid == 100)
            {
                /*
                Tester:Tag:4850
                CoordinatorManager:1:get_n_nodes:2
                */
                int index_4850 = -1;
                int index_n_nodes_2 = -1;
                for (int i = 0; i < tester_events.size; i++)
                {
                    if ("Tag:4850" in tester_events[i]) index_4850 = i;
                    if ("get_n_nodes:2" in tester_events[i]) index_n_nodes_2 = i;
                }
                assert(index_4850 >= 0);
                assert(index_n_nodes_2 > index_4850);
            }
            else if (pid == 200)
            {
                // TODO
            }

            return null;
        }
    }
}