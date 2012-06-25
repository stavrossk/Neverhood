/*
// MusicResource - decodes BLBSFX music and streams it as Mixer music
// Based on http://wiki.multimedia.cx/index.php?title=BLB
// Copyright (C) 2012  Blaise Roth
// See the LICENSE file for the full terms of the license.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <assert.h>
#include <resource.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

typedef struct {
	Sint16 _curValue;
	Uint8 _shift;
	SDL_RWops* _stream;
	Uint32 _streamLen;
} MusicResource;

static SDL_AudioCVT* cvt;

MusicResource* MusicResource_new(SDL_RWops* stream) {
	MusicResource* this = safemalloc(sizeof(MusicResource));

	if (!cvt) {
		cvt = safemalloc(sizeof(SDL_AudioCVT));
		SDL_BuildSpecAudioCVT(cvt, AUDIO_S16LSB, 1, 22050);
		if (cvt->len_mult != 1 || cvt->len_ratio != 1)
			error("Obtained audio did not meet minimum requirements");
	}

	this->_curValue = 0;
	this->_shift = 5;
	this->_stream = stream;
	this->_streamLen = SDL_RWlen(stream);

	return this;
}

/* Only call this if the the smacker music player is definitely not hooked */
void MusicResource_destroy() {
	MusicResource* this = Mix_GetMusicHookData();
	Mix_HookMusic(NULL, NULL);

	if (this) {
		SDL_RWclose(this->_stream);
		safefree(this);
	}
}

static void MusicResource_player(void* udata, Uint8* buf, int len) {
	if (!udata || Mix_PausedMusic()) return;
	MusicResource* this = (MusicResource*)udata;

	int inputLen;
	Sint8* inputBuf;
	if (this->_shift == 0xFF) { /* uncompressed PCM */
		inputLen = len;
		inputBuf = buf;
	} else {                   /* DW ADPCM compressed */
		inputLen = len / 2;
		inputBuf = buf + inputLen;
	}

	int remainingLen = this->_streamLen - SDL_RWtell(this->_stream);
	SDL_RWread(this->_stream, inputBuf, inputLen, 1);

	Sint8* inputLoopPos;
	if (inputLen >= remainingLen) { /* loop */
		SDL_RWseek(this->_stream, 0, SEEK_SET);
		inputLoopPos = inputBuf + remainingLen;
		SDL_RWread(this->_stream, inputLoopPos, inputLen - remainingLen, 1);
	}

	if (this->_shift != 0xFF) { /* DW ADPCM compressed */
		Sint8* inputEnd = inputBuf + inputLen;
		Sint16* outputBuf = (Sint16*)buf;

		while (inputBuf < inputEnd) {
			this->_curValue += *inputBuf++;
			*outputBuf++ = this->_curValue << this->_shift;
			if(inputBuf == inputLoopPos) this->_curValue = 0;
		}
	}

	cvt->buf = buf;
	cvt->len = len;
	SDL_ConvertAudio(cvt);
}

void MusicResource_play(MusicResource* this) {
	Mix_HookMusic(MusicResource_player, (void*)this);
}

MODULE = Games::Neverhood::MusicResource		PACKAGE = Games::Neverhood::MusicResource		PREFIX = Neverhood_MusicResource_

MusicResource*
Neverhood_MusicResource_new(CLASS, stream)
		const char* CLASS
		SDL_RWops* stream
	CODE:
		RETVAL = MusicResource_new(stream);
	OUTPUT:
		RETVAL

void
Neverhood_MusicResource_destroy(CLASS)
		const char* CLASS
	CODE:
		MusicResource_destroy();

void
Neverhood_MusicResource_play(THIS)
		MusicResource* THIS
	CODE:
		MusicResource_play(THIS);
