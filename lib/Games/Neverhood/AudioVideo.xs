/*
// AudioVideo - Miscellaneous audio/video things that are better written in C, but called from Perl
// Copyright (C) 2012  Blaise Roth
// See the LICENSE file for the full terms of the license.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>

SDL_Surface* AudioVideo_mirrorSurface(SDL_Surface* surface)
{
	SDL_Surface* mirrored_surface = SDL_ConvertSurface(surface, surface->format, surface->flags);

	Uint8* pixels = surface->pixels;
	Uint8* mirrored_pixels = mirrored_surface->pixels;
	Uint8* pixels_end = pixels + surface->h * surface->pitch;

	Uint16 off = surface->w - 1;
	Uint16 x;
	while (pixels < pixels_end) {
		for (x = 0; x < surface->w; x++)
			mirrored_pixels[x] = pixels[off - x];

		pixels += surface->pitch;
		mirrored_pixels += surface->pitch;
	}

	return mirrored_surface;
}

MODULE = Games::Neverhood::AudioVideo		PACKAGE = Games::Neverhood::AudioVideo		PREFIX = Neverhood_AudioVideo_

SDL_Surface*
Neverhood_AudioVideo_mirror_surface(surface)
		SDL_Surface* surface
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = AudioVideo_mirrorSurface(surface);
	OUTPUT:
		RETVAL
