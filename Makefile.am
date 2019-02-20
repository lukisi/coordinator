NULL = 
ACLOCAL_AMFLAGS = -I m4
.PHONY: check

noinst_LTLIBRARIES = \
	libcoord.la \
	$(NULL)

TESTS = \
	test_serialization \
	first \
	$(NULL)

check_PROGRAMS = \
	test_serialization \
	system_peer \
	$(NULL)

libcoord_la_SOURCES = \
	api.vala \
	coord.vala \
	rngen.vala \
	fk_database.vala \
	peer_service.vala \
	serializables.vala \
	$(NULL)

libcoord_la_VALAFLAGS = \
	-H coord.h \
	--library coord \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
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
	testsuites/test_serialization/test_serialization.vala \
	testsuites/test_serialization/serializables.vala \
	$(NULL)

test_serialization_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(JSON_PREFIX)/share/vala-0.36/vapi \
	--vapidir $(NTKDCOMMON_VAPIDIR) \
	--vapidir $(NTKDRPC_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg json-glib-1.0 \
	--pkg ntkd-common \
	--pkg ntkdrpc \
	$(NULL)

test_serialization_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(NTKDCOMMON_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(NULL)

test_serialization_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSONGLIB_LIBS) \
	$(NTKDCOMMON_LIBS) \
	$(NTKDRPC_LIBS) \
	$(NULL)

system_peer_SOURCES =  \
	testsuites/system_peer/system_peer.vala \
	testsuites/system_peer/rpc/module_stubs.vala \
	testsuites/system_peer/rpc/skeleton_factory.vala \
	testsuites/system_peer/rpc/stub_factory.vala \
	testsuites/system_peer/serializables.vala \
	testsuites/system_peer/rngen.vala \
	testsuites/system_peer/peers_helpers.vala \
	testsuites/system_peer/coord_helpers.vala \
	testsuites/system_peer/coord_signals.vala \
	coord.vapi \
	$(NULL)

system_peer_VALAFLAGS = \
	--vapidir $(GEE_PREFIX)/share/vala/vapi \
	--vapidir $(TASKLETSYSTEM_VAPIDIR) \
	--vapidir $(PTHTASKLET_VAPIDIR) \
	--vapidir $(NTKDCOMMON_VAPIDIR) \
	--vapidir $(NTKDRPC_VAPIDIR) \
	--vapidir $(PEERS_VAPIDIR) \
	--pkg gee-0.8 \
	--pkg ntkd-common \
	--pkg tasklet-system \
	--pkg pth-tasklet \
	--pkg ntkdrpc \
	--pkg peers \
	$(NULL)

system_peer_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NTKDCOMMON_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(PTHTASKLET_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(PEERS_CFLAGS) \
	$(NULL)

system_peer_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(NTKDCOMMON_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(PTHTASKLET_LIBS) \
	$(NTKDRPC_LIBS) \
	$(PEERS_LIBS) \
	$(builddir)/libcoord.la \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(srcdir)/coord.vapi \
	$(NULL)
