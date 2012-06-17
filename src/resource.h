#ifndef __RESOURCE_H__
#define __RESOURCE_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>

void Resource_unpackSpriteRLE(SDL_RWops* stream, SDL_Surface* surface) {
	Uint16 rows   = SDL_RWreadUint16(stream);
	Uint16 chunks = SDL_RWreadUint16(stream);

	Uint8* dest = surface->pixels;
	do {
		if (chunks == 0) {
			dest += rows * surface->pitch;
		} else {
			while (rows-- > 0) {
				Uint16 rowChunks = chunks;
				while (rowChunks-- > 0) {
					Uint16 skip = SDL_RWreadUint16(stream);
					Uint16 copy = SDL_RWreadUint16(stream);
					SDL_RWread(stream, dest + skip, copy, 1);
				}
				dest += surface->pitch;
			}
		}
		rows   = SDL_RWreadUint16(stream);
		chunks = SDL_RWreadUint16(stream);
	} while (rows > 0);
}

#endif
