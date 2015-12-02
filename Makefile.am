NULL = 
ACLOCAL_AMFLAGS = -I m4

noinst_LTLIBRARIES = \
	libcoord.la \
	$(NULL)

TESTS = \
	test_serialization \
	test_1 \
	test_2 \
	$(NULL)

check_PROGRAMS = \
	test_serialization \
	simulator \
	$(NULL)

libcoord_la_SOURCES = \
	coord.vala \
	serialize_helpers.vala \
	$(NULL)

libcoord_la_VALAFLAGS = \
	-H coord.h \
	--library coord \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg ntkd-tasklet-system \
	--pkg ntkdrpc\
	--pkg zcd-tasklet-system \
	--pkg peers \
	$(NULL)

libcoord_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(PEERS_CFLAGS) \
	$(NULL)

libcoord_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSONGLIB_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(NTKDRPC_LIBS) \
	$(PEERS_LIBS) \
	$(NULL)

# test_serialization does some tests on internal classes, hence we need to compile
#  it with source files, not with the convenience library. The source files
#  are symbolic links to avoid name clashes with vala-generated C files.
test_serialization_SOURCES = \
	testsuites/serialization/serialization.vala \
	testsuites/serialization/coord.vala \
	testsuites/serialization/serialize_helpers.vala \
	$(NULL)

test_serialization_VALAFLAGS = \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg ntkd-tasklet-system \
	--pkg ntkdrpc\
	--pkg zcd-tasklet-system \
	--pkg peers \
	$(NULL)

test_serialization_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(PEERS_CFLAGS) \
	$(NULL)

test_serialization_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSONGLIB_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(NTKDRPC_LIBS) \
	$(PEERS_LIBS) \
	$(NULL)

simulator_SOURCES =  \
	testsuites/simulator/simulator.vala \
	testsuites/simulator/tasklet_system_tasklet.vala \
	coord.vapi \
	$(NULL)

simulator_VALAFLAGS = \
	--pkg gee-0.8 \
	--pkg ntkd-tasklet-system \
	--pkg tasklet \
	--pkg ntkdrpc \
	--pkg zcd-tasklet-system \
	--pkg peers \
	--pkg json-glib-1.0 \
	$(NULL)

simulator_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(TASKLET_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(PEERS_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(NULL)

simulator_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(TASKLET_LIBS) \
	$(NTKDRPC_LIBS) \
	$(PEERS_LIBS) \
	$(JSONGLIB_LIBS) \
	$(builddir)/libcoord.la \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(srcdir)/coord.vapi \
	$(NULL)

coord.vapi: libcoord_la_vala.stamp
	$(NULL)

