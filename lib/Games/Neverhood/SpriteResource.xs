/*
// SpriteResource - decodes Neverhood image files and loads them as a surface
// Based on the ScummVM Neverhood Engine's sprite resource code
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <resource.h>
#include <sprite.h>
#include <memory.h>
#include <SDL/SDL.h>

typedef struct {
	SDL_Surface* surface;
	Uint16 x;
	Uint16 y;
} SpriteResource;

SpriteResource* SpriteResource_new (ResourceEntry* entry)
{
	SpriteResource* this = safemalloc(sizeof(SpriteResource));
	
	if (entry->type != 2)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	Uint8* sprite_buffer = ResourceEntry_getBuffer(entry);
	Uint16* buffer = (Uint16*)sprite_buffer;

	Uint16 flags = *buffer++;

	Uint16 width, height;
	if (flags & 2) {
		width  = *buffer++;
		height = *buffer++;
	} else {
		width  = 1;
		height = 1;
	}
	this->surface = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 8, 0, 0, 0, 0);

	if (flags & 4) {
		this->x = *buffer++;
		this->y = *buffer++;
	} else {
		this->x = 0;
		this->y = 0;
	}

	Uint8* buf = (Uint8*)buffer;

	if (flags & 8) {
		SDL_SetColors(this->surface, (SDL_Color*)buf, 0, 256);
		buf += 1024;
	}
	else {
		SDL_Color colors[256];
		memset(colors, 255, 1024);
		SDL_SetColors(this->surface, colors, 0, 256);
	}

	if (flags & 0x10) {
		if (flags & 1)
			unpackSpriteRLE(buf, this->surface);
		else {
			Uint8* dest = this->surface->pixels;
			int source_pitch = (width + 3) & 0xFFFC;

			while (height-- > 0) {
				memcpy(dest, buf, source_pitch);
				buf  += source_pitch;
				dest += this->surface->pitch;
			}
		}
	}

	safefree(sprite_buffer);

	return this;
}

MODULE = Games::Neverhood::SpriteResource		PACKAGE = Games::Neverhood::SpriteResource		PREFIX = Neverhood_SpriteResource_

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

void
Neverhood_SpriteResource_DESTROY (THIS)
		SpriteResource* THIS
	CODE:
		SDL_FreeSurface(THIS->surface);
		safefree(THIS);
