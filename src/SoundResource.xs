#include <SoundResource.h>

MODULE = Games::Neverhood::SoundResource		PACKAGE = Games::Neverhood::SoundResource		PREFIX = Neverhood_SoundResource_

SoundResource*
Neverhood_SoundResource_new (CLASS, entry)
		const char* CLASS
		ResourceEntry* entry
	CODE:
		RETVAL = SoundResource_new(entry);
	OUTPUT:
		RETVAL

Uint32
Neverhood_SoundResource_play (THIS, loops)
		SoundResource* THIS
		int loops
	CODE:
		RETVAL = SoundResource_play(THIS, loops);
	OUTPUT:
		RETVAL

void
Neverhood_SoundResource_stop (THIS, id)
		SoundResource* THIS
		Uint32 id
	CODE:
		SoundResource_stop(THIS, id);

void
Neverhood_SoundResource_init ()
	CODE:
		SoundResource_init();

void
Neverhood_SoundResource_DESTROY (THIS)
		SoundResource* THIS
	CODE:
		SoundResource_destroy(THIS);
