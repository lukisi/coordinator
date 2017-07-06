/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2017 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
 *
 *  Netsukuku is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Netsukuku is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Netsukuku.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

namespace Netsukuku.Coordinator
{
    public interface ICoordinatorReservation : Object
    {
        public abstract int get_levels();
        public abstract int get_gsize(int lvl);
        public abstract int get_lvl();
        public abstract int get_pos();
        public abstract int get_eldership();
        public abstract int get_upper_pos(int lvl);
        public abstract int get_upper_eldership(int lvl);
    }

    public interface ICoordinatorNeighborMap : Object
    {
        public abstract int get_levels();
        public abstract int get_gsize(int lvl);
        public abstract int get_free_pos_count(int lvl);
    }
}
