using Gee;
using Netsukuku;
using Netsukuku.PeerServices;
using TaskletSystem;

namespace SystemPeer
{
    bool schedule_task_add_gateway(string task)
    {
        if (task.has_prefix("add_gateway,"))
        {
            string remain = task.substring("add_gateway,".length);
            string[] args = remain.split(",");
            if (args.length != 6) error("bad args num in task 'add_gateway'");
            int64 ms_wait;
            if (! int64.try_parse(args[0], out ms_wait)) error("bad args ms_wait in task 'add_identity'");
            int64 my_id;
            if (! int64.try_parse(args[1], out my_id)) error("bad args my_id in task 'add_identity'");
            int64 arc_num;
            int64 peer_id_num;
            string[] parts = args[2].split("+");
            if (parts.length != 2) error("bad identity_arc in task 'add_identity'");
            {
                if (! int64.try_parse(parts[0], out arc_num)) error("bad arc_num in identity_arc in task 'add_identity'");
            }
            {
                if (! int64.try_parse(parts[1], out peer_id_num)) error("bad peer_id_num in identity_arc in task 'add_identity'");
            }
            int64 lvl;
            if (! int64.try_parse(args[3], out lvl)) error("bad args lvl in task 'add_identity'");
            int64 pos;
            if (! int64.try_parse(args[4], out pos)) error("bad args pos in task 'add_identity'");
            int64 insert_at;
            if (! int64.try_parse(args[5], out insert_at)) error("bad args insert_at in task 'add_identity'");
            print(@"INFO: in $(ms_wait) ms will add gateway(lvl=$(lvl),pos=$(pos),index=$(insert_at)) to identity #$(my_id): identity_arc '$(arc_num)+$(peer_id_num)'.\n");
            AddGatewayTasklet s = new AddGatewayTasklet(
                (int)ms_wait,
                (int)my_id,
                (int)arc_num,
                (int)peer_id_num,
                (int)lvl,
                (int)pos,
                (int)insert_at);
            tasklet.spawn(s);
            return true;
        }
        else return false;
    }

    class AddGatewayTasklet : Object, ITaskletSpawnable
    {
        public AddGatewayTasklet(
            int ms_wait,
            int my_id,
            int arc_num,
            int peer_id_num,
            int lvl,
            int pos,
            int insert_at)
        {
            this.ms_wait = ms_wait;
            this.my_id = my_id;
            this.arc_num = arc_num;
            this.peer_id_num = peer_id_num;
            this.lvl = lvl;
            this.pos = pos;
            this.insert_at = insert_at;
        }
        private int ms_wait;
        private int my_id;
        private int arc_num;
        private int peer_id_num;
        private int lvl;
        private int pos;
        private int insert_at;

        public void * func()
        {
            tasklet.ms_wait(ms_wait);

            // find identity_data
            NodeID nodeid = fake_random_nodeid(pid, my_id);
            IdentityData identity_data = find_local_identity(nodeid);
            assert(identity_data != null);

            // find ia
            PseudoArc pseudoarc = arc_list[arc_num];
            NodeID peer_nodeid = fake_random_nodeid(pseudoarc.peer_pid, peer_id_num);
            IdentityArc? ia = identity_data.identity_arcs_find(pseudoarc, peer_nodeid);
            if (ia == null) error(@"not found IdentityArc for $(arc_num)+$(peer_id_num)");

            assert(identity_data.gateways.has_key(lvl));
            if (! identity_data.gateways[lvl].has_key(pos))
                identity_data.gateways[lvl][pos] = new ArrayList<IdentityArc>();
            if (insert_at < 0)
                identity_data.gateways[lvl][pos].add(ia);
            else if (identity_data.gateways[lvl][pos].size <= insert_at)
                identity_data.gateways[lvl][pos].add(ia);
            else
                identity_data.gateways[lvl][pos].insert(insert_at, ia);

            return null;
        }
    }
}