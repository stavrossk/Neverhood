#include <SpriteResource.h>

MODULE = Neverhood::SpriteResource		PACKAGE = Neverhood::SpriteResource		PREFIX = Neverhood_SpriteResource_

SpriteResource*
Neverhood_SpriteResource_new (CLASS, entry)
		const char* CLASS
		ResourceEntry* entry
	CODE:
		RETVAL = SpriteResource_new(entry);
	OUTPUT:
		RETVAL

SDL_Surface*
Neverhood_SpriteResource_get_surface (THIS)
		SpriteResource* THIS
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = cloneSurface(THIS->surface);
	OUTPUT:
		RETVAL

Uint16
Neverhood_SpriteResource_get_x (THIS)
		SpriteResource* THIS
	CODE:
		RETVAL = THIS->x;
	OUTPUT:
		RETVAL

Uint16
Neverhood_SpriteResource_get_y (THIS)
		SpriteResource* THIS
	CODE:
		RETVAL = THIS->y;
	OUTPUT:
		RETVAL

SDL_Palette*
Neverhood_SpriteResource_get_palette (THIS)
		SpriteResource* THIS
	INIT:
		const char* CLASS = "SDL::Palette";
	CODE:
		if (THIS->no_palette) RETVAL = NULL;
		else RETVAL = THIS->surface->format->palette;
	OUTPUT:
		RETVAL

void
Neverhood_SpriteResource_DESTROY (THIS)
		SpriteResource* THIS
	CODE:
		SpriteResource_destroy(THIS);
