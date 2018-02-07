/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2018 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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
    public interface ICoordinatorMap : Object
    {
        public abstract int get_levels();
        public abstract int get_gsize(int lvl);
        public abstract int get_n_nodes();
        public abstract Gee.List<int> get_free_pos(int lvl);
    }

    public errordomain HandlingImpossibleError {
        GENERIC
    }

    public interface INumberOfNodesHandler : Object
    {
        public abstract void number_of_nodes() throws HandlingImpossibleError;
    }

    public interface IEvaluateEnterHandler : Object
    {
        public abstract Object evaluate_enter(int lvl, Object evaluate_enter_data) throws HandlingImpossibleError;
    }

    public interface IBeginEnterHandler : Object
    {
        public abstract void begin_enter() throws HandlingImpossibleError;
    }

    public interface ICompletedEnterHandler : Object
    {
        public abstract void completed_enter() throws HandlingImpossibleError;
    }

    public interface IAbortEnterHandler : Object
    {
        public abstract void abort_enter() throws HandlingImpossibleError;
    }

    public class Reservation : Object
    {
        public int new_pos;
        public int new_eldership;
    }
}
