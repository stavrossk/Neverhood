#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

typedef struct {
	Sint16 _curValue;
	Uint8 _shift;
	SDL_RWops* _stream;
	Uint32 _streamLen;
	SDL_AudioCVT* _wav_cvt;
} MusicResource;

void MusicResource_player(void* udata, Uint8* buf, int len) {
	if(!udata || Mix_PausedMusic()) return;
	MusicResource* this = (MusicResource*)udata;

	int inputLen;
	Sint8* inputBuf;
	if(this->_shift == 0xFF) { /* uncompressed PCM */
		inputLen = len;
		inputBuf = buf;
	} else {                   /* DW ADPCM compressed */
		inputLen = len / 2;
		inputBuf = buf + inputLen;
	}
	
	int remainingLen = this->_streamLen - SDL_RWtell(this->_stream);
	SDL_RWread(this->_stream, inputBuf, inputLen, 1);
	
	Sint8* inputLoopPos;
	if(inputLen >= remainingLen) { /* loop */
		SDL_RWseek(this->_stream, 0, SEEK_SET);
		inputLoopPos = inputBuf + remainingLen;
		SDL_RWread(this->_stream, inputLoopPos, inputLen - remainingLen, 1);
	}
	
	if(this->_shift != 0xFF) { /* DW ADPCM compressed */
		Sint8* inputEnd = inputBuf + inputLen;
		Sint16* outputBuf = (Sint16*)buf;
		
		while(inputBuf < inputEnd) {
			this->_curValue += *inputBuf++;
			*outputBuf++ = this->_curValue << this->_shift;
			if(inputBuf == inputLoopPos) this->_curValue = 0;
		}
	}

	this->_wav_cvt->buf = buf;
	this->_wav_cvt->len = len;
	SDL_ConvertAudio(this->_wav_cvt);
}

void MusicResource_destroy(MusicResource* this) {
	safefree(this->_wav_cvt);
	safefree(this);
}

void MusicResource_new(SDL_RWops* stream) {
	Mix_HookMusic(NULL, NULL);
	SDL_LockAudio();
	
	MusicResource* this = Mix_GetMusicHookData();
	if(this) MusicResource_destroy(this);

	this = safemalloc(sizeof(MusicResource));

	this->_curValue = 0;
	this->_shift = 5;
	this->_stream = stream;
	this->_streamLen = SDL_RWlen(stream);
	
	int frequency, channels;
	Uint16 format;
	Mix_QuerySpec(&frequency, &format, &channels);

	this->_wav_cvt = safemalloc(sizeof(SDL_AudioCVT));
	SDL_BuildAudioCVT(this->_wav_cvt, AUDIO_S16SYS, 1, 22050, format, channels, frequency);

	Mix_HookMusic(MusicResource_player, (void*)this);
	SDL_UnlockAudio();
}

MODULE = Games::Neverhood::MusicResource		PACKAGE = Games::Neverhood::MusicResource		PREFIX = Neverhood_MusicResource_

void
Neverhood_MusicResource_new(CLASS, stream)
		const char* CLASS
		SDL_RWops* stream
	CODE:
		MusicResource_new(stream);
