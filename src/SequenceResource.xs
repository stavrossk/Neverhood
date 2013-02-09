#include <SequenceResource.h>

MODULE = Games::Neverhood::SequenceResource		PACKAGE = Games::Neverhood::SequenceResource		PREFIX = Neverhood_SequenceResource_

SequenceResource*
Neverhood_SequenceResource_new (CLASS, entry)
		const char* CLASS
		ResourceEntry* entry
	CODE:
		RETVAL = SequenceResource_new(entry);
	OUTPUT:
		RETVAL

Uint16
Neverhood_SequenceResource_get_frame_count (THIS)
		SequenceResource* THIS
	CODE:
		RETVAL = THIS->frameCount;
	OUTPUT:
		RETVAL

SDL_Palette*
Neverhood_SequenceResource_get_palette (THIS)
		SequenceResource* THIS
	INIT:
		const char* CLASS = "SDL::Palette";
	CODE:
		RETVAL = &THIS->palette;
	OUTPUT:
		RETVAL

SDL_Surface*
Neverhood_SequenceResource_get_frame_surface (THIS, frame)
		SequenceResource* THIS
		int frame
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = cloneSurface(SequenceResource_getFrame(THIS, frame)->surface);
	OUTPUT:
		RETVAL

Sint16
Neverhood_SequenceResource_get_frame_ticks (THIS, frame)
		SequenceResource* THIS
		int frame
	CODE:
		RETVAL = SequenceResource_getFrame(THIS, frame)->ticks;
	OUTPUT:
		RETVAL

Sint16
Neverhood_SequenceResource_get_frame_draw_offset_x (THIS, frame)
		SequenceResource* THIS
		int frame
	CODE:
		RETVAL = SequenceResource_getFrame(THIS, frame)->drawOffsetX;
	OUTPUT:
		RETVAL

Sint16
Neverhood_SequenceResource_get_frame_draw_offset_y (THIS, frame)
		SequenceResource* THIS
		int frame
	CODE:
		RETVAL = SequenceResource_getFrame(THIS, frame)->drawOffsetY;
	OUTPUT:
		RETVAL

Sint16
Neverhood_SequenceResource_get_frame_delta_x (THIS, frame)
		SequenceResource* THIS
		int frame
	CODE:
		RETVAL = SequenceResource_getFrame(THIS, frame)->deltaX;
	OUTPUT:
		RETVAL

Sint16
Neverhood_SequenceResource_get_frame_delta_y (THIS, frame)
		SequenceResource* THIS
		int frame
	CODE:
		RETVAL = SequenceResource_getFrame(THIS, frame)->deltaY;
	OUTPUT:
		RETVAL

SDL_Rect*
Neverhood_SequenceResource_get_frame_collision_bounds_offset (THIS, frame)
		SequenceResource* THIS
		int frame
	INIT:
		const char* CLASS = "SDL::Rect";
	CODE:
		RETVAL = cloneRect(&(SequenceResource_getFrame(THIS, frame)->collisionBoundsOffset));
	OUTPUT:
		RETVAL

void
Neverhood_SequenceResource_DESTROY (THIS)
		SequenceResource* THIS
	CODE:
		SequenceResource_destroy(THIS);
