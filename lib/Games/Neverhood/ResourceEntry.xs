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
#include <SDL/SDL.h>

typedef struct {
	Uint32 id1;
	Uint16 id2;
	Uint16 extDataSize;
	Sint32 fileSize;
	Uint32 fileCount;
} BlbHeader;

void ResourceEntry_loadFromArchive(const char* filename, HV* hash) {
	SDL_RWops* stream = SDL_RWopen(filename);

	BlbHeader header;
	header.id1         = SDL_ReadLE32(stream);
	header.id2         = SDL_ReadLE16(stream);
	header.extDataSize = SDL_ReadLE16(stream);
	header.fileSize    = SDL_ReadLE32(stream);
	header.fileCount   = SDL_ReadLE32(stream);

	if (header.id1 != 0x2004940 || header.id2 != 7 || header.fileSize != SDL_RWlen(stream))
		error("Archive %s seems to be corrupt", filename);

	/* file hashes */
	Uint32* hashes = safemalloc(header.fileCount * 4);
	int i;
	for (i = 0; i < header.fileCount; i++) {
		hashes[i] = SDL_ReadLE32(stream);
	}

	/* extDataPos = headerSize + fileCount * (hashSize + entrySize) */
	Uint16 extDataPos = 16 + header.fileCount * (4 + 20);
	
	int filename_len = strlen(filename) + 1;
	char* filename_copy = safemalloc(filename_len);
	memcpy(filename_copy, filename, filename_len);

	/* file records */
	for (i = 0; i < header.fileCount; i++) {
		ResourceEntry* entry = safemalloc(sizeof(ResourceEntry));
		entry->filename      = filename_copy;
		entry->type          = SDL_RWreadUint8(stream);
		entry->comprType     = SDL_RWreadUint8(stream);
		entry->extDataOffset = SDL_ReadLE16(stream) + extDataPos;
		entry->timeStamp     = SDL_ReadLE32(stream);
		entry->offset        = SDL_ReadLE32(stream);
		entry->size          = SDL_ReadLE32(stream);
		entry->unpackedSize  = SDL_ReadLE32(stream);
		
		char key[9]; /* max 32-bit value is 8 Fs (FFFFFFFF) */

		int klen = sprintf(key, "%08X", hashes[i]);
		SV* val = *hv_fetch(hash, key, klen, 1);

		if(SvOK(val)) {
			ResourceEntry* valEntry = (ResourceEntry*)SvIV((SV*)SvRV(val));
			if(valEntry->timeStamp > entry->timeStamp) continue;
		}

		sv_setref_pv(val, "Games::Neverhood::ResourceEntry", (void*)entry);
	}

	safefree(hashes);
}

MODULE = Games::Neverhood::ResourceEntry		PACKAGE = Games::Neverhood::ResourceEntry		PREFIX = Neverhood_ResourceEntry_

void
Neverhood_ResourceEntry_load_from_archive(CLASS, filename, hashref)
		const char* CLASS
		const char* filename
		SV* hashref
	CODE:
		if (SvTYPE(SvRV(hashref)) != SVt_PVHV) error("Hashref needed");
		HV* hash = (HV*)SvRV(hashref);
		ResourceEntry_loadFromArchive(filename, hash);

void
Neverhood_ResourceEntry_DESTROY(THIS)
		ResourceEntry* THIS
	CODE:
		safefree(THIS);

const char*
Neverhood_ResourceEntry_get_filename(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->filename;
	OUTPUT:
		RETVAL

Uint8
Neverhood_ResourceEntry_get_type(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->type;
	OUTPUT:
		RETVAL

Uint8
Neverhood_ResourceEntry_get_compr_type(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->comprType;
	OUTPUT:
		RETVAL

Uint16
Neverhood_ResourceEntry_get_ext_data_offset(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->extDataOffset;
	OUTPUT:
		RETVAL

Uint32
Neverhood_ResourceEntry_get_time_stamp(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->timeStamp;
	OUTPUT:
		RETVAL

Uint32
Neverhood_ResourceEntry_get_offset(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->offset;
	OUTPUT:
		RETVAL

Uint32
Neverhood_ResourceEntry_get_size(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->size;
	OUTPUT:
		RETVAL

Uint32
Neverhood_ResourceEntry_get_unpacked_size(THIS)
		ResourceEntry* THIS
	CODE:
		RETVAL = THIS->unpackedSize;
	OUTPUT:
		RETVAL
