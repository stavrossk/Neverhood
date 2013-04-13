#include <ResourceEntry.h>

MODULE = Neverhood::ResourceEntry		PACKAGE = Neverhood::ResourceEntry		PREFIX = Neverhood_ResourceEntry_

void
Neverhood_ResourceEntry_load_archives (prefix, hashref)
		const char* prefix
		SV* hashref
	CODE:
		if (SvTYPE(SvRV(hashref)) != SVt_PVHV) error("Hashref needed");
		HV* hash = (HV*)SvRV(hashref);
		ResourceEntry_loadArchives(prefix, hash);

void
Neverhood_ResourceEntry_DESTROY (THIS)
		ResourceEntry* THIS
	CODE:
		ResourceEntry_destroy(THIS);

const char*
Neverhood_ResourceEntry_get_filename (THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->filename;
	OUTPUT:
		RETVAL
		
Uint32
Neverhood_ResourceEntry_get_key (THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->key;
	OUTPUT:
		RETVAL

Uint8
Neverhood_ResourceEntry_get_type (THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->type;
	OUTPUT:
		RETVAL

Uint8
Neverhood_ResourceEntry_get_compr_type (THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->comprType;
	OUTPUT:
		RETVAL

Uint32
Neverhood_ResourceEntry_get_time_stamp (THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->timeStamp;
	OUTPUT:
		RETVAL

Uint32
Neverhood_ResourceEntry_get_disk_size (THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->diskSize;
	OUTPUT:
		RETVAL

Uint32
Neverhood_ResourceEntry_get_size (THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->size;
	OUTPUT:
		RETVAL
