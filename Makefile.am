NULL = 
ACLOCAL_AMFLAGS = -I m4
.PHONY: check

noinst_LTLIBRARIES = \
	libcoord.la \
	$(NULL)

TESTS = \
	test_serialization \
	$(NULL)

check_PROGRAMS = \
	test_serialization \
	$(NULL)

# TESTS = \
# 	test_serialization \
# 	test_1 \
# 	test_2 \
# 	test_3 \
# 	$(NULL)

# check_PROGRAMS = \
# 	test_serialization \
# 	simulator \
# 	$(NULL)

libcoord_la_SOURCES = \
	api.vala \
	coord.vala \
	serializables.vala \
	$(NULL)

libcoord_la_VALAFLAGS = \
	-H coord.h \
	--library coord \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.32/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(NTKDCOMMON_VAPIDIR) \
	--vapidir $(NTKDRPC_VAPIDIR) \
	--vapidir $(PEERS_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg ntkd-common \
	--pkg ntkdrpc\
	--pkg peers \
	$(NULL)

libcoord_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NTKDCOMMON_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(PEERS_CFLAGS) \
	$(NULL)

libcoord_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSONGLIB_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(NTKDCOMMON_LIBS) \
	$(NTKDRPC_LIBS) \
	$(PEERS_LIBS) \
	$(NULL)

# test_serialization does some tests on internal classes, hence we need to compile
#  it with source files, not with the convenience library. The source files
#  are symbolic links to avoid name clashes with vala-generated C files.
test_serialization_SOURCES = \
	testsuites/serialization/test_serialization.vala \
	testsuites/serialization/api.vala \
	testsuites/serialization/serializables.vala \
	$(NULL)

test_serialization_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.32/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(NTKDCOMMON_VAPIDIR) \
	--vapidir $(NTKDRPC_VAPIDIR) \
	--vapidir $(PEERS_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg tasklet-system \
	--pkg ntkd-common \
	--pkg ntkdrpc\
	--pkg peers \
	$(NULL)

test_serialization_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NTKDCOMMON_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(PEERS_CFLAGS) \
	$(NULL)

test_serialization_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSONGLIB_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(NTKDCOMMON_LIBS) \
	$(NTKDRPC_LIBS) \
	$(PEERS_LIBS) \
	$(NULL)

# simulator_SOURCES =  \
# 	testsuites/simulator/simulator.vala \
# 	testsuites/simulator/tasklet_system_tasklet.vala \
# 	coord.vapi \
# 	$(NULL)

# simulator_VALAFLAGS = \
# 	--pkg gee-0.8 \
# 	--pkg ntkd-tasklet-system \
# 	--pkg tasklet \
# 	--pkg ntkdrpc \
# 	--pkg zcd-tasklet-system \
# 	--pkg peers \
# 	--pkg json-glib-1.0 \
# 	$(NULL)

# simulator_CPPFLAGS = \
# 	-w \
# 	$(GOBJECT_CFLAGS) \
# 	$(GEE_CFLAGS) \
# 	$(TASKLETSYSTEM_CFLAGS) \
# 	$(TASKLET_CFLAGS) \
# 	$(NTKDRPC_CFLAGS) \
# 	$(PEERS_CFLAGS) \
# 	$(JSONGLIB_CFLAGS) \
# 	$(NULL)

# simulator_LDADD = \
# 	$(GOBJECT_LIBS) \
# 	$(GEE_LIBS) \
# 	$(TASKLETSYSTEM_LIBS) \
# 	$(TASKLET_LIBS) \
# 	$(NTKDRPC_LIBS) \
# 	$(PEERS_LIBS) \
# 	$(JSONGLIB_LIBS) \
# 	$(builddir)/libcoord.la \
# 	$(NULL)

MAINTAINERCLEANFILES = \
	$(srcdir)/coord.vapi \
	$(NULL)

coord.vapi: libcoord_la_vala.stamp
	$(NULL)

