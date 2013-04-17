/*
// helper - general purpose functions
*/

#ifndef __HELPER__
#define __HELPER__

#include <helper.h>
#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

#define error(...) {\
	fprintf(stderr, __VA_ARGS__);\
	fprintf(stderr, " at %s line %d\n", __FILE__, __LINE__);\
	fprintf(stderr, "-----\n");\
	exit(1);\
}

#define debug(...) {\
	if (1||SvTRUE(get_sv("Neverhood::Options::Debug", 0))) {\
		fprintf(stderr, __VA_ARGS__);\
		fprintf(stderr, "\n");\
		fprintf(stderr, "----- at %s line %d\n", __FILE__, __LINE__);\
	}\
}

Uint8 SDL_RWreadUint8 (SDL_RWops* stream)
{
	Uint8 num;
	SDL_RWread(stream, &num, 1, 1);
	return num;
}

/* open a RWops file for reading and die on error */
SDL_RWops* SDL_RWopen (const char* filename)
{
	SDL_RWops* stream = SDL_RWFromFile(filename, "r");
	if (!stream) error("%s", SDL_GetError());
	return stream;
}

void SDL_BuildSpecAudioCVT (SDL_AudioCVT *cvt, Uint16 src_format, Uint8 src_channels, int src_rate)
{
	int dst_rate, dst_channels;
	Uint16 dst_format;
	Mix_QuerySpec(&dst_rate, &dst_format, &dst_channels);
	SDL_BuildAudioCVT(cvt, src_format, src_channels, src_rate, dst_format, dst_channels, dst_rate);
	if (cvt->len_mult <= 0 || cvt->len_ratio <= 0)
		error("Neverhood's audio can not be converted to your opened audio");
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
	SDL_Rect* new_rect = (SDL_Rect*)safemalloc(sizeof(SDL_Rect));
	new_rect->x = rect->x;
	new_rect->y = rect->y;
	new_rect->w = rect->w;
	new_rect->h = rect->h;
	return new_rect;
}

#endif
