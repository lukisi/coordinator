using Netsukuku.Coordinator;
using Netsukuku.PeerServices;

using Gee;
using Netsukuku;
using TaskletSystem;

namespace SystemPeer
{
    void start_listen_pathname(string listen_pathname)
    {
        skeleton_factory.start_stream_system_listen(listen_pathname);
        tasklet.ms_wait(1);
        print(@"started stream_system_listen $(listen_pathname).\n");
    }
    void stop_listen_pathname(string listen_pathname)
    {
        skeleton_factory.stop_stream_system_listen(listen_pathname);
        tasklet.ms_wait(1);
        print(@"stopped stream_system_listen $(listen_pathname).\n");
    }
    string listen_pathname_for_inside_gnode(Gee.List<int> positions, int fp)
    {
        assert(positions.size > 0);
        string ret = "conn";
        foreach (int pos in positions) ret = @"$(ret)_$(pos)";
        return @"$(ret)_inside_$(fp)";
    }
    void start_listen_inside_gnodes(Gee.List<int> positions, Gee.List<int> fp_list, int first_level=0)
    {
        assert(positions.size == levels);
        assert(positions.size == fp_list.size);
        for (int l = first_level; l < positions.size; l++)
        {
            start_listen_pathname(
                listen_pathname_for_inside_gnode(
                    positions.slice(0,l+1), fp_list[l]));
        }
    }
    void stop_listen_inside_gnodes(Gee.List<int> positions, Gee.List<int> fp_list, int first_level=0)
    {
        for (int l = positions.size-1; l >= first_level; l--)
        {
            stop_listen_pathname(
                listen_pathname_for_inside_gnode(
                    positions.slice(0,l+1), fp_list[l]));
        }
    }
}