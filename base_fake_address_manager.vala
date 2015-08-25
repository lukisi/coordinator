/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

using Netsukuku;
using Netsukuku.ModRpc;

public class FakeCoordinatorSkeleton : Object,
                                  ICoordinatorManagerSkeleton
{
	public virtual Netsukuku.ICoordinatorReservation ask_reservation
	(int lvl, zcd.ModRpc.CallerInfo? caller = null)
	throws Netsukuku.SaturatedGnodeError
    {
        error("FakeCoordinatorSkeleton: you must override method ask_reservation.");
    }

	public virtual Netsukuku.ICoordinatorNeighborMap retrieve_neighbor_map
	(zcd.ModRpc.CallerInfo? caller = null)
    {
        error("FakeCoordinatorSkeleton: you must override method retrieve_neighbor_map.");
    }
}

public class FakeCoordinatorStub : Object,
                                  ICoordinatorManagerStub
{
	public virtual Netsukuku.ICoordinatorReservation ask_reservation
	(int lvl)
	throws Netsukuku.SaturatedGnodeError, zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("FakeAddressManagerStub: you must override method ask_reservation.");
    }

	public virtual Netsukuku.ICoordinatorNeighborMap retrieve_neighbor_map()
	throws zcd.ModRpc.StubError, zcd.ModRpc.DeserializeError
    {
        error("FakeAddressManagerStub: you must override method retrieve_neighbor_map.");
    }
}

