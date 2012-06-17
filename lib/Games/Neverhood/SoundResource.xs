#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

typedef Mix_Chunk SoundResource;
/*	int allocated;
	Uint8* abuf;
	Uint32 alen;
	Uint8 volume;
} Mix_Chunk; */

SoundResource* SoundResource_new(SDL_RWops* stream) {
	SoundResource* this = safemalloc(sizeof(SoundResource));
	this->allocated = 0; /* commandeering this for use as a refcount */
	this->volume = MIX_MAX_VOLUME;

	Uint32 inputLen = SDL_RWseek(stream, 0, SEEK_END);
	SDL_RWseek(stream, 0, SEEK_SET);

	Sint8* inputBuf = safemalloc(inputLen);
	SDL_RWread(stream, inputBuf, inputLen, 1);

	Uint8 shift = 5;
	if(shift == 0xFF) { /* uncompressed PCM */
		this->alen = inputLen;
		this->abuf = inputBuf;
	}
	else { /* DW ADPCM compressed */
		this->alen = inputLen * 2;
		this->abuf = safemalloc(this->alen);

		Uint8* inputEnd = inputBuf + inputLen;
		Uint16* outputBuf = (Uint16*)this->abuf;
		Sint16 curValue = 0x0000;

		while(inputBuf < inputEnd) {
			curValue += *inputBuf++;
			*outputBuf++ = curValue << shift;
		}
	}

	int frequency;
	Uint16 format;
	int channels;
	Mix_QuerySpec(&frequency, &format, &channels);
	debug("obtained: freq=%d, format=0x%04X, channels=%d", frequency, format, channels);

	SDL_AudioCVT wav_cvt;
	SDL_BuildAudioCVT(&wav_cvt, AUDIO_S16SYS, 1, 22050, format, channels, frequency);

	wav_cvt.buf = this->abuf;
	wav_cvt.len = this->alen;
	SDL_ConvertAudio(&wav_cvt);

	return this;
}

void SoundResource_incRefcount(SoundResource* this) {
	this->allocated++;
}

void SoundResource_decRefcount(SoundResource* this) {
	if(--this->allocated <= 0) {
		this->allocated = 1;
		Mix_FreeChunk(this);
	}
}

void SoundResource_finished(int channel) {
	SoundResource* this = Mix_GetChunk(channel);
	if(this) {
		SoundResource_decRefcount(this);
	}
}

void SoundResource_play(SoundResource* this, int loops) {
	SDL_LockAudio();
	int channel = Mix_PlayChannel(-1, this, loops);
	if(channel >= 0) {
		SoundResource_incRefcount(this);
	}
	SDL_UnlockAudio();
}

MODULE = Games::Neverhood::SoundResource		PACKAGE = Games::Neverhood::SoundResource		PREFIX = Neverhood_SoundResource_

BOOT:
	av_push(get_av("Games::Neverhood::SoundResource::ISA", 0), newSVpv("SDL::Mixer::MixChunk", 0));
	Mix_ChannelFinished(SoundResource_finished);

SoundResource*
Neverhood_SoundResource_new(CLASS, stream)
		const char* CLASS
		SDL_RWops* stream
	CODE:
		RETVAL = SoundResource_new(stream);
		SoundResource_incRefcount(RETVAL);
	OUTPUT:
		RETVAL

void
Neverhood_SoundResource_inc_refcount(THIS)
		SoundResource* THIS
	CODE:
		SoundResource_incRefcount(THIS);

void
Neverhood_SoundResource_DESTROY(THIS)
		SoundResource* THIS
	CODE:
		SoundResource_decRefcount(THIS);

void
Neverhood_SoundResource_play(THIS, loops)
		SoundResource* THIS
		int loops
	CODE:
		SoundResource_play(THIS, loops);
