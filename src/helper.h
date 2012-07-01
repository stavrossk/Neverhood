/*
// helper.h
// general purpose functions
*/

#ifndef __HELPER_H__
#define __HELPER_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

#define error(...) {\
	fprintf(stderr, __VA_ARGS__);\
	fprintf(stderr, " at %s line %d\n", __FILE__, __LINE__);\
	exit(1);\
}

#define debug(...) {\
	if(SvTRUE(get_sv("Games::Neverhood::Debug", 0))) {\
		fprintf(stderr, __VA_ARGS__);\
		fprintf(stderr, "\n----- at %s line %d\n", __FILE__, __LINE__);\
	}\
}

Uint8 SDL_RWreadUint8(SDL_RWops* stream) {
	Uint8 num;
	SDL_RWread(stream, &num, 1, 1);
	return num;
}

/* convenience function for returning the length of a RWops file */
int SDL_RWlen(SDL_RWops* stream) {
	int cur = SDL_RWtell(stream);
	int len = SDL_RWseek(stream, 0, SEEK_END);
	SDL_RWseek(stream, cur, SEEK_SET);
	return len;
}

#endif
