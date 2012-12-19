/*
// PaletteResource - loads palette files into SDL Palettes
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
#include <SDL/SDL.h>

typedef SDL_Palette PaletteResource;
/*	int ncolors
	SDL_Color* colors
} SDL_Palette; */

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

void PaletteResource_DESTROY (PaletteResource* this)
{
	safefree(this->colors);
	safefree(this);
}

MODULE = Games::Neverhood::PaletteResource		PACKAGE = Games::Neverhood::PaletteResource		PREFIX = Neverhood_PaletteResource_

PaletteResource*
Neverhood_PaletteResource_new (CLASS, entry)
		const char* CLASS
		ResourceEntry* entry
	CODE:
		RETVAL = PaletteResource_new(entry);
	OUTPUT:
		RETVAL

void
Neverhood_PaletteResource_DESTROY (THIS)
		PaletteResource* THIS
	CODE:
		PaletteResource_DESTROY(THIS);
