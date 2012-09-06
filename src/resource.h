/*
// resource.h
// functions common to resources
*/

#ifndef __RESOURCE_H__
#define __RESOURCE_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>
#include <blast.h>
#include <memory.h>

#define SOUND_CHANNELS 8

typedef struct {
	const char* filename;
	Uint8 type;
	Uint8 comprType;
	Uint16 extDataOffset;
	Uint32 timeStamp;
	Uint32 offset;
	Uint32 size;
	Uint32 unpackedSize;
} ResourceEntry;

typedef struct {
	Uint8* buf;
	int len;
} Buffer;

static unsigned ResourceEntry_infun(void* how, unsigned char** buf) {
	Buffer* in = (Buffer*)how;

	*buf = in->buf;
	return in->len;
}

static int ResourceEntry_outfun(void* how, unsigned char* buf, unsigned len) {
	Uint8** outputBuf = (Uint8**)how;

	memcpy(*outputBuf, buf, len);
	*outputBuf += len;
	return 0;
}

Uint8* ResourceEntry_getBuffer(ResourceEntry* this)
{
	Uint8* inputBuf = safemalloc(this->size);
	SDL_RWops* stream = SDL_RWopen(this->filename);
	SDL_RWseek(stream, this->offset, SEEK_SET);
	SDL_RWread(stream, inputBuf, this->size, 1);
	SDL_RWclose(stream);

	switch (this->comprType) {
		case 1: /* Uncompressed */
			return inputBuf;
		case 3:
		{ /* DCL-compressed */
			Buffer* in = safemalloc(sizeof(Buffer));
			in->buf = inputBuf;
			in->len = this->size;

			Uint8* outputBuf = safemalloc(this->unpackedSize);

			int err = blast(ResourceEntry_infun, in, ResourceEntry_outfun, &outputBuf);
			if(err)
				error("Blast error: %d; archive: %s", err, this->filename);

			safefree(inputBuf);
			safefree(in);

			return outputBuf;
		}
		default:
			error("Unknown compression type %d", this->comprType);
	}
}

SDL_RWops* ResourceEntry_getStream(ResourceEntry* this) {
	if (this->comprType != 1)
		error("Can't get stream from compression type: %d; archive: %s", this->comprType, this->filename);
	SDL_RWops* stream = SDL_RWopen(this->filename);
	SDL_RWseek(stream, this->offset, SEEK_SET);

	return stream;
}

Uint8 ResourceEntry_getExtData8(ResourceEntry* this) {
	SDL_RWops* stream = SDL_RWopen(this->filename);
	SDL_RWseek(stream, this->extDataOffset, SEEK_SET);
	Uint8 data = SDL_RWreadUint8(stream);
	SDL_RWclose(stream);

	return data;
}

void unpackSpriteRLE(SDL_RWops* stream, SDL_Surface* surface) {
	Uint16 rows   = SDL_ReadLE16(stream);
	Uint16 chunks = SDL_ReadLE16(stream);

	Uint8* dest = surface->pixels;
	do {
		if (chunks == 0) {
			dest += rows * surface->pitch;
		} else {
			while (rows-- > 0) {
				Uint16 rowChunks = chunks;
				while (rowChunks-- > 0) {
					Uint16 skip = SDL_ReadLE16(stream);
					Uint16 copy = SDL_ReadLE16(stream);
					SDL_RWread(stream, dest + skip, copy, 1);
				}
				dest += surface->pitch;
			}
		}
		rows   = SDL_ReadLE16(stream);
		chunks = SDL_ReadLE16(stream);
	} while (rows > 0);
}

int SDL_BuildSpecAudioCVT(SDL_AudioCVT *cvt, Uint16 src_format, Uint8 src_channels, int src_rate) {
	int dst_rate, dst_channels;
	Uint16 dst_format;
	Mix_QuerySpec(&dst_rate, &dst_format, &dst_channels);
	SDL_BuildAudioCVT(cvt, src_format, src_channels, src_rate, dst_format, dst_channels, dst_rate);
	if(cvt->len_mult <= 0 || cvt->len_ratio <= 0)
		error("Neverhood's audio can not be converted to your opened audio");
}

#endif
