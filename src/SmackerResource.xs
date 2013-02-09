#include <SmackerResource.h>

MODULE = Games::Neverhood::SmackerResource		PACKAGE = Games::Neverhood::SmackerResource		PREFIX = Neverhood_SmackerResource_

SmackerResource*
Neverhood_SmackerResource_new (CLASS, entry)
		const char* CLASS
		ResourceEntry* entry
	CODE:
		RETVAL = SmackerResource_new(entry);
	OUTPUT:
		RETVAL

int
Neverhood_SmackerResource_next_frame (THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = SmackerResource_nextFrame(THIS);
	OUTPUT:
		RETVAL

void
Neverhood_SmackerResource_stop (THIS)
		SmackerResource* THIS
	CODE:
		SmackerResource_stop(THIS);

SDL_Surface*
Neverhood_SmackerResource_get_surface (THIS)
		SmackerResource* THIS
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = THIS->surface;
	OUTPUT:
		RETVAL

Sint32
Neverhood_SmackerResource_get_cur_frame (THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = THIS->curFrame;
	OUTPUT:
		RETVAL

Uint32
Neverhood_SmackerResource_get_frame_count (THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = THIS->frameCount;
	OUTPUT:
		RETVAL

double
Neverhood_SmackerResource_get_frame_rate (THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = THIS->frameRate;
	OUTPUT:
		RETVAL

void
Neverhood_SmackerResource_DESTROY (THIS)
		SmackerResource* THIS
	CODE:
		SmackerResource_destroy(THIS);
