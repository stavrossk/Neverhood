/*
// SpriteResource - decodes Neverhood image files and loads them as a surface
// Based on the ScummVM Neverhood Engine's sprite resource code
*/

#ifndef __SPRITE_RESOURCE__
#define __SPRITE_RESOURCE__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <ResourceEntry.h>
#include <memory.h>
#include <SDL/SDL.h>

typedef struct {
	SDL_Surface* surface;
	Uint16 x;
	Uint16 y;
	bool no_palette;
} SpriteResource;

SpriteResource* SpriteResource_new (ResourceEntry* entry);
void SpriteResource_destroy (SpriteResource* this);
void unpackSpriteRLE (Uint8* buffer, SDL_Surface* surface);

SpriteResource* SpriteResource_new (ResourceEntry* entry)
{
	SpriteResource* this = (SpriteResource*)safemalloc(sizeof(SpriteResource));

	if (entry->type != 2)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	Uint8* sprite_buffer = ResourceEntry_getBuffer(entry);
	Uint16* buffer = (Uint16*)sprite_buffer;

	Uint16 flags = *buffer++;

	Uint16 width, height;
	if (flags & 2) {
		width  = *buffer++;
		height = *buffer++;
	} else {
		width  = 1;
		height = 1;
	}
	this->surface = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 8, 0, 0, 0, 0);

	if (flags & 4) {
		this->x = *buffer++;
		this->y = *buffer++;
	} else {
		this->x = 0;
		this->y = 0;
	}

	Uint8* buf = (Uint8*)buffer;

	if (flags & 8) {
		SDL_SetColors(this->surface, (SDL_Color*)buf, 0, 256);
		buf += 1024;
	}
	else {
		SDL_Color colors[256];
		memset(colors, 255, 1024);
		SDL_SetColors(this->surface, colors, 0, 256);
		this->no_palette = 1;
	}

	if (flags & 0x10) {
		if (flags & 1)
			unpackSpriteRLE(buf, this->surface);
		else {
			Uint8* dest = this->surface->pixels;
			int source_pitch = (width + 3) & 0xFFFC;

			while (height-- > 0) {
				memcpy(dest, buf, source_pitch);
				buf  += source_pitch;
				dest += this->surface->pitch;
			}
		}
	}

	safefree(sprite_buffer);

	return this;
}

void SpriteResource_destroy (SpriteResource* this)
{
	SDL_FreeSurface(this->surface);
	safefree(this);
}

void unpackSpriteRLE (Uint8* buffer, SDL_Surface* surface)
{
	Uint16 rows   = *(Uint16*)buffer;
	Uint16 chunks = *(Uint16*)(buffer+2);
	buffer += 4;

	Uint8* dest = surface->pixels;
	do {
		if (chunks == 0) {
			dest += rows * surface->pitch;
		} else {
			while (rows-- > 0) {
				Uint16 row_chunks = chunks;
				while (row_chunks-- > 0) {
					Uint16 skip = *(Uint16*)buffer;
					Uint16 copy = *(Uint16*)(buffer+2);
					buffer += 4;
					memcpy(dest + skip, buffer, copy);
					buffer += copy;
				}
				dest += surface->pitch;
			}
		}
		rows   = *(Uint16*)buffer;
		chunks = *(Uint16*)(buffer+2);
		buffer += 4;
	} while (rows > 0);
}

#endif
