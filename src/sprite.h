/*
// resource.h
// functions common to sprites
*/

#ifndef __SPRITE_H__
#define __SPRITE_H__

#include <helper.h>
#include <SDL/SDL.h>
#include <memory.h>

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

SDL_Surface* cloneSurface (SDL_Surface* surface)
{
	SDL_Surface* new_surface = SDL_ConvertSurface(surface, surface->format, surface->flags);
	if (!new_surface)
		error("%s", SDL_GetError());
	return new_surface;
}

SDL_Rect* cloneRect (SDL_Rect* rect)
{
	SDL_Rect* new_rect = safemalloc(sizeof(SDL_Rect));
	new_rect->x = rect->x;
	new_rect->y = rect->y;
	new_rect->w = rect->w;
	new_rect->h = rect->h;
	return new_rect;
}

#endif
