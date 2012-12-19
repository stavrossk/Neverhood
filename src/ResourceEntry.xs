/*
// BlbArchive - opens Blb archives and makes resources from them
// Based on the ScummVM Neverhood Engine's BLB archive code
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <resource.h>
#include <stdio.h>
#include <SDL/SDL.h>

typedef struct {
	Uint32 id1;
	Uint16 id2;
	Uint16 extDataSize;
	Sint32 fileSize;
	Uint32 fileCount;
} BlbHeader;

char*  a_filename;
char*  c_filename;
char* hd_filename;
char*  i_filename;
char*  m_filename;
char*  s_filename;
char*  t_filename;

static void ResourceEntry_loadArchive (char* filename, const char* prefix, const char* name, HV* hash)
{
	filename = safemalloc(strlen(prefix) + strlen(name) + 1);
	sprintf(filename, "%s%s", prefix, name);

	SDL_RWops* stream = SDL_RWopen(filename);

	BlbHeader header;
	header.id1         = SDL_ReadLE32(stream);
	header.id2         = SDL_ReadLE16(stream);
	header.extDataSize = SDL_ReadLE16(stream);
	header.fileSize    = SDL_ReadLE32(stream);
	header.fileCount   = SDL_ReadLE32(stream);

	if (header.id1 != 0x2004940 || header.id2 != 7 || header.fileSize != SDL_RWlen(stream))
		error("Archive %s seems to be corrupt", filename);

	Uint32* keys = safemalloc(header.fileCount * 4);
	int i;
	for (i = 0; i < header.fileCount; i++) {
		keys[i] = SDL_ReadLE32(stream);
	}

	/* ext_data_pos = header_size + file_count * (hash_size + entry_size) */
	Uint16 ext_data_pos = 16 + header.fileCount * (4 + 20);

	/* file records */
	for (i = 0; i < header.fileCount; i++) {
		ResourceEntry* entry   = safemalloc(sizeof(ResourceEntry));
		entry->filename        = filename;
		entry->key             = keys[i];
		entry->type            = SDL_RWreadUint8(stream);
		entry->comprType       = SDL_RWreadUint8(stream);
		Uint16 ext_data_offset = SDL_ReadLE16(stream);
		entry->extDataOffset   = ext_data_offset > 0 ? ext_data_pos + ext_data_offset - 1 : 0;
		entry->timeStamp       = SDL_ReadLE32(stream);
		entry->offset          = SDL_ReadLE32(stream);
		entry->diskSize        = SDL_ReadLE32(stream);
		entry->size            = SDL_ReadLE32(stream);

		char key[9]; /* max 32-bit value is 8 Fs (FFFFFFFF) */

		int klen = sprintf(key, "%08X", keys[i]);
		SV* val = *hv_fetch(hash, key, klen, 1);

		if (SvOK(val)) {
			ResourceEntry* valEntry = (ResourceEntry*)SvIV((SV*)SvRV(val));
			if (valEntry->timeStamp > entry->timeStamp) continue;
		}

		sv_setref_pv(val, "Games::Neverhood::ResourceEntry", (void*)entry);
	}

	safefree(keys);
}

void ResourceEntry_loadArchives (const char* prefix, HV* hash)
{
	ResourceEntry_loadArchive( a_filename, prefix,  "a.blb", hash);
	ResourceEntry_loadArchive( c_filename, prefix,  "c.blb", hash);
	ResourceEntry_loadArchive(hd_filename, prefix, "hd.blb", hash);
	ResourceEntry_loadArchive( i_filename, prefix,  "i.blb", hash);
	ResourceEntry_loadArchive( m_filename, prefix,  "m.blb", hash);
	ResourceEntry_loadArchive( s_filename, prefix,  "s.blb", hash);
	ResourceEntry_loadArchive( t_filename, prefix,  "t.blb", hash);
}

MODULE = Games::Neverhood::ResourceEntry		PACKAGE = Games::Neverhood::ResourceEntry		PREFIX = Neverhood_ResourceEntry_

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
		safefree(THIS);

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
