/*
// CUtil - routines like palette and color swapping, color keying, mirroring
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef __C_UTIL__
#define __C_UTIL__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>

void CUtil_mirror (SDL_Surface* surface);
void CUtil_setPalette (SDL_Surface* surface, SDL_Palette* palette);
void CUtil_setColorKeying (SDL_Surface* surface, bool keying);
void CUtil_swapColors (SDL_Surface* surface, Uint8 old_index, Uint8 new_index);
bool CUtil_rectsEqual (SDL_Rect* rect, SDL_Rect* rect2);

void CUtil_mirror (SDL_Surface* surface)
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

void CUtil_setPalette (SDL_Surface* surface, SDL_Palette* palette)
{
	SDL_SetColors(surface, palette->colors, 0, palette->ncolors);
}

void CUtil_setColorKeying (SDL_Surface* surface, bool keying)
{
	if (keying) {
		SDL_Color color = surface->format->palette->colors[0];
		SDL_SetColorKey(surface, SDL_SRCCOLORKEY | SDL_RLEACCEL,
			SDL_MapRGB(surface->format, color.r, color.g, color.b));
	}
	else
		SDL_SetColorKey(surface, 0, 0);
}

void CUtil_swapColors (SDL_Surface* surface, Uint8 old_index, Uint8 new_index)
{
	SDL_Color* color = surface->format->palette->colors;
	SDL_Color old_color = color[old_index];
	color[old_index] = color[new_index];
	color[new_index] = old_color;
}

bool CUtil_rectsEqual (SDL_Rect* rect, SDL_Rect* rect2)
{
	return rect->x == rect2->x
	    && rect->y == rect2->y
	    && rect->w == rect2->w
	    && rect->h == rect2->h
	;
}

#endif
