/*
// SequenceResource - decodes Neverhood sequence files and loads them as a sequence of surfaces
// Based on the ScummVM Neverhood Engine's animation resource code
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef __SEQUENCE_RESOURCE__
#define __SEQUENCE_RESOURCE__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <ResourceEntry.h>
#include <SpriteResource.h>
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

SequenceResource* SequenceResource_new (ResourceEntry* entry);
SequenceFrame* SequenceResource_getFrame (SequenceResource* this, int frame);
void SequenceResource_destroy (SequenceResource* this);

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

SequenceFrame* SequenceResource_getFrame (SequenceResource* this, int frame)
{
	if (frame < 0 || frame >= this->frameCount)
		error("Requested out-of-bounds frame: %d from sequence with frame count: %d", frame, this->frameCount);
	return &(this->frames[frame]);
}

void SequenceResource_destroy (SequenceResource* this)
{
	int frame_index;
	for (frame_index = 0; frame_index < this->frameCount; frame_index++) {
		SDL_FreeSurface(this->frames[frame_index].surface);
	}
	safefree(this->frames);
	safefree(this->palette.colors);
	safefree(this);
}

#endif
