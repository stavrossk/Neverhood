#ifndef __HELPER_H__
#define __HELPER_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <SDL/SDL.h>

#define error(...) {\
	printf(__VA_ARGS__);\
	printf(" at %s line %d\n", __FILE__, __LINE__);\
	exit(1);\
}

#define debug(...)\
	if(SvTRUE(get_sv("Games::Neverhood::Debug", 0))) {\
		fprintf(stderr, __VA_ARGS__);\
		fprintf(stderr, " at %s line %d\n", __FILE__, __LINE__);\
	}\

/* convenience functions for returning numbers read from RWops */
static Uint32 SDL_RWreadUint32(SDL_RWops* stream) {
	Uint32 num;
	SDL_RWread(stream, &num, 4, 1);
	return num;
}
static Uint16 SDL_RWreadUint16(SDL_RWops* stream) {
	Uint16 num;
	SDL_RWread(stream, &num, 2, 1);
	return num;
}
static Uint8 SDL_RWreadUint8(SDL_RWops* stream) {
	Uint8 num;
	SDL_RWread(stream, &num, 1, 1);
	return num;
}

#endif
