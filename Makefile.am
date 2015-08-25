NULL = 
ACLOCAL_AMFLAGS = -I m4

noinst_LTLIBRARIES = \
	libcoord.la \
	$(NULL)

noinst_PROGRAMS =  \
	coordclient \
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
	$(NULL)

libcoord_la_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(NULL)

libcoord_la_LIBADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(JSONGLIB_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(NTKDRPC_LIBS) \
	$(NULL)

coordclient_SOURCES =  \
	main.vala \
	tasklet_system_tasklet.vala \
	base_fake_address_manager.vala \
	coord.vapi \
	$(NULL)

coordclient_VALAFLAGS = \
	--pkg gee-0.8 \
	--pkg ntkd-tasklet-system \
	--pkg tasklet \
	--pkg ntkdrpc \
	--pkg zcd-tasklet-system \
	$(NULL)

coordclient_CPPFLAGS = \
	-w \
	$(GOBJECT_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TASKLETSYSTEM_CFLAGS) \
	$(TASKLET_CFLAGS) \
	$(NTKDRPC_CFLAGS) \
	$(NULL)

coordclient_LDADD = \
	$(GOBJECT_LIBS) \
	$(GEE_LIBS) \
	$(TASKLETSYSTEM_LIBS) \
	$(TASKLET_LIBS) \
	$(NTKDRPC_LIBS) \
	$(builddir)/libcoord.la \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(srcdir)/coord.vapi \
	$(NULL)

coord.vapi: libcoord_la_vala.stamp
	$(NULL)

