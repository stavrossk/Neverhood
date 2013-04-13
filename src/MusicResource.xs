#include <MusicResource.h>

MODULE = Neverhood::MusicResource		PACKAGE = Neverhood::MusicResource		PREFIX = Neverhood_MusicResource_

MusicResource*
Neverhood_MusicResource_new (CLASS, entry)
		const char* CLASS
		ResourceEntry* entry
	CODE:
		RETVAL = MusicResource_new (entry);
	OUTPUT:
		RETVAL

void
Neverhood_MusicResource_fade_in (THIS, ms)
		MusicResource* THIS
		int ms
	CODE:
		MusicResource_fadeIn(THIS, ms);

void
Neverhood_MusicResource_fade_out (THIS, ms)
		MusicResource* THIS
		int ms
	CODE:
		MusicResource_fadeOut(THIS, ms);

void
Neverhood_MusicResource_init ()
	CODE:
		MusicResource_init();

void
Neverhood_MusicResource_DESTROY (THIS)
		MusicResource* THIS
	CODE:
		MusicResource_destroy(THIS);
