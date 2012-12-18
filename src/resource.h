/*
// resource.h
// functions common to resources
*/

#ifndef __RESOURCE_H__
#define __RESOURCE_H__

#include <helper.h>
#include <SDL/SDL.h>
#include <blast.h>
#include <memory.h>

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

typedef struct {
	Uint8* buf;
	int size;
} Buffer;

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
