/*
// PaletteResource - loads palette files into SDL Palettes
*/

#ifndef __PALETTE_RESOURCE__
#define __PALETTE_RESOURCE__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <ResourceEntry.h>
#include <SDL/SDL.h>

typedef SDL_Palette PaletteResource;
/*	int ncolors
	SDL_Color* colors
} SDL_Palette; */

PaletteResource* PaletteResource_new (ResourceEntry* entry);
void PaletteResource_destroy (PaletteResource* this);

PaletteResource* PaletteResource_new (ResourceEntry* entry)
{
	PaletteResource* this = safemalloc(sizeof(PaletteResource));

	if (entry->type != 3)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	if (entry->size != 1024)
		error("Palette resource: %08X is of wrong size: %d", entry->key, entry->size);

	this->colors = (SDL_Color*)ResourceEntry_getBuffer(entry);
	this->ncolors = 256;

	return this;
}

void PaletteResource_destroy (PaletteResource* this)
{
	safefree(this->colors);
	safefree(this);
}

#endif
