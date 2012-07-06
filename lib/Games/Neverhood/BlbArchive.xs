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

BlbArchive* BlbArchive_new(const char* filename, SV* hashref) {
	BlbArchive* this = safemalloc(sizeof(BlbArchive));

	SDL_RWops* stream = SDL_RWopen(filename);
	
	this->filename = filename;
	this->stream   = stream;

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

	if (SvTYPE(SvRV(hashref)) != SVt_PVHV)
		error("Hashref needed");
	HV* hash = (HV*)SvRV(hashref);

	/* file records */
	for (i = 0; i < header.fileCount; i++) {
		ResourceHandle* handle = safemalloc(sizeof(ResourceHandle));
		handle->archive      = this;
		handle->type         = SDL_RWreadUint8(stream);
		handle->comprType    = SDL_RWreadUint8(stream);
		handle->extDataOfset = SDL_ReadLE16(stream);
		handle->timeStamp    = SDL_ReadLE32(stream);
		handle->offset       = SDL_ReadLE32(stream);
		handle->size         = SDL_ReadLE32(stream);
		handle->unpackedSize = SDL_ReadLE32(stream);

		char key[30];
		int klen = sprintf(key, "%u", hashes[i]);
		SV** val = hv_fetch(hash, key, klen, 1);

		sv_setref_pv(*val, "Games::Neverhood::ResourceHandle", (void*)handle);
	}
	
	safefree(hashes);

	return this;
}
		// switch (comprType) {
			// case 1: /* Uncompressed */

			// case 3: /* DCL-compressed */

			// default:
				// error("Unknown compression type %d", comprType);
		// }

MODULE = Games::Neverhood::BlbArchive		PACKAGE = Games::Neverhood::BlbArchive		PREFIX = Neverhood_BlbArchive_

BlbArchive*
Neverhood_BlbArchive_new(CLASS, filename, hashref)
		const char* CLASS
		const char* filename
		SV* hashref
	CODE:
		RETVAL = BlbArchive_new(filename, hashref);
	OUTPUT:
		RETVAL
