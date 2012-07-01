/*
// BLBArchive - opens BLB archives and makes resources from them
// Based on the ScummVM Neverhood Engine's BLB archive code
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

typedef struct {
	Resource* _resources;
	Uint8* _extData;
	const char* _filename;
} BLBArchive;

typedef struct {
	Uint32 id1;
	Uint16 id2;
	Uint16 extDataSize;
	Sint32 fileSize;
	Uint32 fileCount;
} BlbHeader;

BLBArchive* BLBArchive_new(const char* filename) {
	BLBArchive* this = safemalloc(sizeof(BLBArchive));
	
	SDL_RWops* stream = SDL_RWFromFile(filename, "r");
	if(!stream) error(SDL_GetError());
	
	

	return this;
}

MODULE = Games::Neverhood::BLBArchive		PACKAGE = Games::Neverhood::BLBArchive		PREFIX = Neverhood_BLBArchive_

BLBArchive*
Neverhood_BLBArchive_new(CLASS, filename)
		const char* CLASS
		const char* filename
	INIT:
		CLASS = "Games::Neverhood::BLBArchive";
	CODE:
		RETVAL = BLBArchive_new(filename);
	OUTPUT:
		RETVAL
