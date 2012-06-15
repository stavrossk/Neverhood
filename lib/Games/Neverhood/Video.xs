#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>

SDL_Surface* Video_mirrorSurface(SDL_Surface* surface)
{
	SDL_Surface* mirrored_surface = SDL_ConvertSurface(surface, surface->format, surface->flags);

	Uint8* pixels = surface->pixels;
	Uint8* mirrored_pixels = mirrored_surface->pixels;
	Uint8* pixels_end = pixels + surface->h * surface->pitch;

	Uint16 off = surface->w - 1;
	Uint16 x;
	while(pixels < pixels_end) {
		for(x = 0; x < surface->w; x++)
			mirrored_pixels[x] = pixels[off - x];

		pixels += surface->pitch;
		mirrored_pixels += surface->pitch;
	}

	return mirrored_surface;
}

MODULE = Games::Neverhood::Video		PACKAGE = Games::Neverhood::Video		PREFIX = Neverhood_Video_

SDL_Surface*
Neverhood_Video_mirror_surface(surface)
		SDL_Surface* surface
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = Video_mirrorSurface(surface);
	OUTPUT:
		RETVAL
