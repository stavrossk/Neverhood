/*
// BlbArchive - opens Blb archives and makes resources from them
// Based on the ScummVM Neverhood Engine's BLB archive code
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef __RESOURCE_ENTRY__
#define __RESOURCE_ENTRY__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <blast.h>
#include <stdio.h>
#include <memory.h>
#include <SDL/SDL.h>

typedef struct {
	char* filename;
	Uint32 key;
	Uint8 type;
	Uint8 comprType;
	Uint32 extDataOffset;
	Uint32 timeStamp;
	Uint32 offset;
	Uint32 diskSize;
	Uint32 size;
} ResourceEntry;

void ResourceEntry_loadArchives (const char* prefix, HV* hash);
void ResourceEntry_destroy (ResourceEntry* this);

Uint8* ResourceEntry_getBuffer (ResourceEntry* this);
SDL_RWops* ResourceEntry_getStream (ResourceEntry* this);
void ResourceEntry_getExtData (ResourceEntry* this, Uint8* ext_data, int bytes);

typedef struct {
	Uint32 id1;
	Uint16 id2;
	Uint16 extDataSize;
	Sint32 fileSize;
	Uint32 fileCount;
} BlbHeader;

typedef struct {
	Uint8* buf;
	int size;
} Buffer;

static char*  a_filename;
static char*  c_filename;
static char* hd_filename;
static char*  i_filename;
static char*  m_filename;
static char*  s_filename;
static char*  t_filename;

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

void ResourceEntry_DESTROY (ResourceEntry* this)
{
	safefree(this);
}

static unsigned ResourceEntry_infun (void* how, unsigned char** buf)
{
	Buffer* in = (Buffer*)how;

	*buf = in->buf;
	return in->size;
}

static int ResourceEntry_outfun (void* how, unsigned char* buf, unsigned size)
{
	Uint8** out_buf = (Uint8**)how;

	memcpy(*out_buf, buf, size);
	*out_buf += size;
	return 0;
}

Uint8* ResourceEntry_getBuffer (ResourceEntry* this)
{
	Uint8* input_buf = safemalloc(this->diskSize);
	SDL_RWops* stream = SDL_RWopen(this->filename);
	SDL_RWseek(stream, this->offset, SEEK_SET);
	SDL_RWread(stream, input_buf, this->diskSize, 1);
	SDL_RWclose(stream);

	switch (this->comprType) {
		case 1: /* Uncompressed */
			return input_buf;
		case 3:
		{ /* DCL-compressed */
			Buffer in;
			in.buf = input_buf;
			in.size = this->diskSize;

			Uint8* out = safemalloc(this->size);
			Uint8* out_buf = out;

			int err = blast(ResourceEntry_infun, &in, ResourceEntry_outfun, &out_buf);
			if (err)
				error("Blast error: %d; archive: %s", err, this->filename);

			safefree(input_buf);

			return out;
		}
		default:
			error("Unknown compression type %d", this->comprType);
	}
}

SDL_RWops* ResourceEntry_getStream (ResourceEntry* this)
{
	if (this->comprType != 1)
		error("Can't get stream from compression type: %d; archive: %s", this->comprType, this->filename);
	SDL_RWops* stream = SDL_RWopen(this->filename);
	SDL_RWseek(stream, this->offset, SEEK_SET);

	return stream;
}

void ResourceEntry_getExtData (ResourceEntry* this, Uint8* ext_data, int bytes)
{
	if (this->extDataOffset == 0)
		error("Resource entry: %08X has no extra data", this->key);
	SDL_RWops* stream = SDL_RWopen(this->filename);
	SDL_RWseek(stream, this->extDataOffset, SEEK_SET);
	SDL_RWread(stream, ext_data, bytes, 1);
	SDL_RWclose(stream);
}

#endif
