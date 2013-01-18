/*
// SurfaceUtil - surface routines like palette and color swapping, color keying, mirroring
// Based on the ScummVM Neverhood Engine's animation resource code
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>

void SurfaceUtil_mirror (SDL_Surface* surface)
{
	int surface_size = surface->h * surface->pitch;
	int half_width = surface->w / 2;
	Uint8* pixel = surface->pixels;

	int ypos, xpos, left, right;
	Uint8 left_pixel;
	for (ypos = 0; ypos < surface_size; ypos += surface->pitch) {
		for (xpos = 0; xpos < half_width; xpos++) {
			left  = ypos + xpos;
			right = ypos + surface->w - xpos - 1;

			left_pixel   = pixel[left];
			pixel[left]  = pixel[right];
			pixel[right] = left_pixel;
		}
	}
}

void SurfaceUtil_setPalette (SDL_Surface* surface, SDL_Palette* palette) {
	SDL_SetColors(surface, palette->colors, 0, palette->ncolors);
}

void SurfaceUtil_setColorKeying (SDL_Surface* surface, bool keying)
{
	if (keying) {
		SDL_Color color = surface->format->palette->colors[0];
		SDL_SetColorKey(surface, SDL_SRCCOLORKEY | SDL_RLEACCEL,
			SDL_MapRGB(surface->format, color.r, color.g, color.b));
	}
	else
		SDL_SetColorKey(surface, 0, 0);
}

void SurfaceUtil_swapColors (SDL_Surface* surface, Uint8 old_index, Uint8 new_index)
{
	SDL_Color* color = surface->format->palette->colors;
	SDL_Color old_color = color[old_index];
	color[old_index] = color[new_index];
	color[new_index] = old_color;
}

void SurfaceUtil_setIcon (const char* filename, SDL_Color* color)
{
	SDL_Surface* icon = SDL_LoadBMP(filename);

	/* Who knows why this doesn't work... */
	/* SDL_SetColorKey(icon, SDL_SRCCOLORKEY, SDL_MapRGB(icon->format, color->r, color->g, color->b)); */

	/* instead we have to set the transparent pixels manually with a mask */
	Uint8 mask[128] = {
		0b00000000,0b00111100,0b00000000,0b00000000,
		0b00000000,0b00111100,0b00000000,0b00000000
	};
	memset(mask + 8, 0xFF, 120);

	SDL_WM_SetIcon(icon, mask);
}

bool SurfaceUtil_rectsEqual (SDL_Rect* rect, SDL_Rect* rect2)
{
	return rect->x == rect2->x
	    && rect->y == rect2->y
	    && rect->w == rect2->w
	    && rect->h == rect2->h
	;
}

MODULE = Games::Neverhood::SurfaceUtil		PACKAGE = Games::Neverhood::SurfaceUtil		PREFIX = Neverhood_SurfaceUtil_

void
Neverhood_SurfaceUtil_mirror (surface)
		SDL_Surface* surface
	CODE:
		SurfaceUtil_mirror(surface);

void
Neverhood_SurfaceUtil_set_palette (surface, palette)
		SDL_Surface* surface
		SDL_Palette* palette
	CODE:
		SurfaceUtil_setPalette(surface, palette);

void
Neverhood_SurfaceUtil_set_color_keying (surface, keying)
		SDL_Surface* surface
		bool keying
	CODE:
		SurfaceUtil_setColorKeying(surface, keying);

void
Neverhood_SurfaceUtil_swap_colors (surface, old_index, new_index)
		SDL_Surface* surface
		Uint8 old_index
		Uint8 new_index
	CODE:
		SurfaceUtil_swapColors(surface, old_index, new_index);

void
Neverhood_SurfaceUtil_set_icon (filename, color)
		const char* filename
		SDL_Color* color
	CODE:
		SurfaceUtil_setIcon(filename, color);

bool
Neverhood_SurfaceUtil_rects_equal (rect, rect2)
		SDL_Rect* rect
		SDL_Rect* rect2
	CODE:
		RETVAL = SurfaceUtil_rectsEqual(rect, rect2);
	OUTPUT:
		RETVAL
