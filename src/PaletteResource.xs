#include <PaletteResource.h>

MODULE = Neverhood::PaletteResource		PACKAGE = Neverhood::PaletteResource		PREFIX = Neverhood_PaletteResource_

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
		PaletteResource_destroy(THIS);
