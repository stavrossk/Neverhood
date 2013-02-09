#include <CUtil.h>

MODULE = Games::Neverhood::CUtil		PACKAGE = Games::Neverhood::CUtil		PREFIX = Neverhood_CUtil_

void
Neverhood_CUtil_mirror (surface)
		SDL_Surface* surface
	CODE:
		CUtil_mirror(surface);

void
Neverhood_CUtil_set_palette (surface, palette)
		SDL_Surface* surface
		SDL_Palette* palette
	CODE:
		CUtil_setPalette(surface, palette);

void
Neverhood_CUtil_set_color_keying (surface, keying)
		SDL_Surface* surface
		bool keying
	CODE:
		CUtil_setColorKeying(surface, keying);

void
Neverhood_CUtil_swap_colors (surface, old_index, new_index)
		SDL_Surface* surface
		Uint8 old_index
		Uint8 new_index
	CODE:
		CUtil_swapColors(surface, old_index, new_index);

void
Neverhood_CUtil_set_icon (filename, color)
		const char* filename
		SDL_Color* color
	CODE:
		CUtil_setIcon(filename, color);

bool
Neverhood_CUtil_rects_equal (rect, rect2)
		SDL_Rect* rect
		SDL_Rect* rect2
	CODE:
		RETVAL = CUtil_rectsEqual(rect, rect2);
	OUTPUT:
		RETVAL
