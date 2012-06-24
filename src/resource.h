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

int SDL_BuildSpecAudioCVT(SDL_AudioCVT *cvt, Uint16 src_format, Uint8 src_channels, int src_rate) {
	int dst_rate, dst_channels;
	Uint16 dst_format;
	Mix_QuerySpec(&dst_rate, &dst_format, &dst_channels);
	SDL_BuildAudioCVT(cvt, src_format, src_channels, src_rate, dst_format, dst_channels, dst_rate);
}

#endif
