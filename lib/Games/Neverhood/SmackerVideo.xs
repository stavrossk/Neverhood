#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <SDL/SDL.h>

typedef struct {
	SDL_Surface* surface;
	Uint32 frame;
} NHC_SmackerVideo;

NHC_SmackerVideo* NHC_SmackerVideo_new(const char* filename) {
	NHC_SmackerVideo* self = safemalloc(sizeof(NHC_SmackerVideo));
	
	self->surface = SDL_CreateRGBSurface(SDL_SWSURFACE, 400, 300, 8, 0, 0, 0, 0);
	self->frame = 0;
	
	return self;
}

int NHC_SmackerVideo_next_frame(NHC_SmackerVideo* self) {
	return 0;
}

MODULE = Games::Neverhood::SmackerVideo		PACKAGE = Games::Neverhood::SmackerVideo		PREFIX = Neverhood_SmackerVideo_

NHC_SmackerVideo*
Neverhood_SmackerVideo_new(CLASS, filename)
		const char* CLASS
		const char* filename
	CODE:
		RETVAL = NHC_SmackerVideo_new(filename);
	OUTPUT:
		RETVAL

int
Neverhood_SmackerVideo_next_frame(SELF)
		NHC_SmackerVideo* SELF
	CODE:
		RETVAL = NHC_SmackerVideo_next_frame(SELF);
	OUTPUT:
		RETVAL

SDL_Surface*
Neverhood_SmackerVideo_get_surface(SELF)
		NHC_SmackerVideo* SELF
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = SELF->surface;
	OUTPUT:
		RETVAL

Uint32
Neverhood_SmackerVideo_get_frame(SELF)
		NHC_SmackerVideo* SELF
	CODE:
		RETVAL = SELF->frame;
	OUTPUT:
		RETVAL

void
Neverhood_SmackerVideo_DESTROY(SELF)
		NHC_SmackerVideo* SELF
	CODE:
		SDL_Video_FreeSurface(SELF->surface);
		safefree(SELF);
