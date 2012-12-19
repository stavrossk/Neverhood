/*
// SpriteResource - decodes Neverhood sequence files and loads them as a sequence of surfaces
// Based on the ScummVM Neverhood Engine's animation resource code
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#undef NDEBUG
#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <sprite.h>
#include <resource.h>
#include <memory.h>
#include <SDL/SDL.h>

typedef struct {
	SDL_Surface* surface;
	Uint32 frameKey;
	Sint16 ticks;
	Uint16 drawOffsetX, drawOffsetY;
	Sint16 deltaX, deltaY;
	SDL_Rect collisionBoundsOffset;
} SequenceFrame;

typedef struct {
	Uint16 frameCount;
	SequenceFrame* frames;
	SDL_Palette palette;
} SequenceResource;

SequenceResource* SequenceResource_new (ResourceEntry* entry)
{
	SequenceResource* this = safemalloc(sizeof(SequenceResource));
	
	if (entry->type != 4)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	Uint8* resource_data = ResourceEntry_getBuffer(entry);
	Uint8* data = resource_data;

	Uint16 anim_list_count     = *(Uint16*)(data);
	Uint16 anim_info_start_ofs = *(Uint16*)(data + 2);
	Uint32 sprite_data_ofs     = *(Uint32*)(data + 4);
	Uint32 palette_data_ofs    = *(Uint32*)(data + 8);
	data += 12;

	Uint16 anim_list_index;
	for (anim_list_index = 0; anim_list_index < anim_list_count; anim_list_index++) {
		if (*(Uint32*)data == entry->key)
			break;
		data += 8;
	}
	assert(anim_list_index < anim_list_count);

	Uint8* sprite_data = resource_data + sprite_data_ofs;

	this->palette.colors = safemalloc(1024);
	if (palette_data_ofs > 0)
		memcpy(this->palette.colors, resource_data + palette_data_ofs, 1024);
	else
		memset(this->palette.colors, 255, 1024);
	this->palette.ncolors = 256;

	this->frameCount            = *(Uint16*)(data + 4);
	Uint16 frame_list_start_ofs = *(Uint16*)(data + 6);

	this->frames = safemalloc(sizeof(SequenceFrame) * this->frameCount);

	data = resource_data + anim_info_start_ofs + frame_list_start_ofs;

	Uint16 frame_index;
	for (frame_index = 0; frame_index < this->frameCount; frame_index++) {
		SequenceFrame* frame = &(this->frames[frame_index]);

		frame->frameKey                = *(Uint32*)(data);
		frame->ticks                   = *(Uint16*)(data + 4);
		frame->drawOffsetX             = *(Uint16*)(data + 6);
		frame->drawOffsetY             = *(Uint16*)(data + 8);
		Uint16 width                   = *(Uint16*)(data + 10);
		Uint16 height                  = *(Uint16*)(data + 12);
		frame->deltaX                  = *(Uint16*)(data + 14);
		frame->deltaY                  = *(Uint16*)(data + 16);
		frame->collisionBoundsOffset.x = *(Uint16*)(data + 18);
		frame->collisionBoundsOffset.y = *(Uint16*)(data + 20);
		frame->collisionBoundsOffset.w = *(Uint16*)(data + 22);
		frame->collisionBoundsOffset.h = *(Uint16*)(data + 24);
		Uint32 sprite_data_offset      = *(Uint32*)(data + 28);
		data += 32;

		Uint8* curr_sprite_data = sprite_data + sprite_data_offset;
		frame->surface = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 8, 0, 0, 0, 0);
		unpackSpriteRLE(curr_sprite_data, frame->surface);
		SDL_SetColors(frame->surface, this->palette.colors, 0, this->palette.ncolors);
	}

	safefree(resource_data);

	return this;
}

static SequenceFrame* SequenceResource_getFrame (SequenceResource* this, int frame)
{
	if (frame < 0 || frame >= this->frameCount)
		error("Requested out-of-bounds frame: %d from sequence with frame count: %d", frame, this->frameCount);
	return &(this->frames[frame]);
}

void SequenceResource_DESTROY (SequenceResource* this)
{
	int frame_index;
	for (frame_index = 0; frame_index < this->frameCount; frame_index++) {
		SDL_FreeSurface(this->frames[frame_index].surface);
	}
	safefree(this->frames);
	safefree(this->palette.colors);
	safefree(this);
}

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
Neverhood_SequenceResource_get_collision_bounds_offset (THIS, frame)
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
		SequenceResource_DESTROY(THIS);
