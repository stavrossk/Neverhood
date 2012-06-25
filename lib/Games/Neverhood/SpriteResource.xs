/*
// SpriteResource - decodes Neverhood image files and loads them as a surface
// Based on the ScummVM Neverhood Engine's sprite resource code
// Copyright (C) 2012  Blaise Roth
// See the LICENSE file for the full terms of the license.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <resource.h>
#include <SDL/SDL.h>

typedef struct {
	SDL_Surface* _surface;
	Uint16 _x;
	Uint16 _y;
} SpriteResource;

SpriteResource* SpriteResource_new(SDL_RWops* stream) {
	SpriteResource* this = safemalloc(sizeof(SpriteResource));

	Uint16 flags = SDL_RWreadUint16(stream);

	Uint16 width, height;
	if (flags & 2) {
		width  = SDL_RWreadUint16(stream);
		height = SDL_RWreadUint16(stream);
	} else {
		width  = 1;
		height = 1;
	}
	this->_surface = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 8, 0, 0, 0, 0);

	if (flags & 4) {
		this->_x = SDL_RWreadUint16(stream);
		this->_y = SDL_RWreadUint16(stream);
	} else {
		this->_x = 0;
		this->_y = 0;
	}

	if (flags & 8) {
		SDL_RWread(stream, this->_surface->format->palette->colors, 1024, 1);
		SDL_SetColors(this->_surface, this->_surface->format->palette->colors, 0, 256);
	}

	if (flags & 0x10) {
		if (flags & 1)
			Resource_unpackSpriteRLE(stream, this->_surface);
		else {
			Uint8* dest = this->_surface->pixels;
			int sourcePitch = (width + 3) & 0xFFFC;

			while (height-- > 0) {
				SDL_RWread(stream, dest, sourcePitch, 1);
				dest += this->_surface->pitch;
			}
		}
	}

	return this;
}

MODULE = Games::Neverhood::SpriteResource		PACKAGE = Games::Neverhood::SpriteResource		PREFIX = Neverhood_SpriteResource_

SpriteResource*
Neverhood_SpriteResource_new(CLASS, stream)
		const char* CLASS
		SDL_RWops* stream
	CODE:
		RETVAL = SpriteResource_new(stream);
	OUTPUT:
		RETVAL

SDL_Surface*
Neverhood_SpriteResource_get_surface(THIS)
		SpriteResource* THIS
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = THIS->_surface;
	OUTPUT:
		RETVAL

Uint16
Neverhood_SpriteResource_get_x(THIS)
		SpriteResource* THIS
	CODE:
		RETVAL = THIS->_x;
	OUTPUT:
		RETVAL

Uint16
Neverhood_SpriteResource_get_y(THIS)
		SpriteResource* THIS
	CODE:
		RETVAL = THIS->_y;
	OUTPUT:
		RETVAL

void
Neverhood_SpriteResource_DESTROY(THIS)
		SpriteResource* THIS
	CODE:
		safefree(THIS);
