/*
// MusicResource - decodes BLBSFX music and streams it as Mixer music
// Based on http://wiki.multimedia.cx/index.php?title=BLB
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

	int _fading;
	int _fade_step;
	int _fade_steps;
} MusicResource;

static SDL_AudioCVT cvt;

Uint8* myBuf;

int msPerStep;

MusicResource* MusicResource_new(SDL_RWops* stream) {
	MusicResource* this = safemalloc(sizeof(MusicResource));

	this->_curValue = 0;
	this->_shift = 5;
	this->_stream = stream;
	this->_streamLen = SDL_RWlen(stream);

	return this;
}

/* Only call this if the the smacker music player is definitely not hooked */
void MusicResource_stop() {
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
		inputLen = len * cvt.len_ratio;
		inputBuf = myBuf;
	} else {                    /* DW ADPCM compressed */
		inputLen = len / 2.0 * cvt.len_ratio;
		inputBuf = myBuf + inputLen;
	}

	int remainingLen = this->_streamLen - SDL_RWtell(this->_stream);
	SDL_RWread(this->_stream, inputBuf, remainingLen < inputLen ? remainingLen : inputLen, 1);

	Sint8* inputLoopPos;
	if (inputLen >= remainingLen) { /* loop */
		SDL_RWseek(this->_stream, 0, SEEK_SET);
		inputLoopPos = inputBuf + remainingLen;
		SDL_RWread(this->_stream, inputLoopPos, inputLen - remainingLen, 1);
		this->_curValue = 0;
	}

	if (this->_shift != 0xFF) { /* DW ADPCM compressed */
		Sint8* inputEnd = inputBuf + inputLen;
		Sint16* outputBuf = (Sint16*)myBuf;

		while (inputBuf < inputEnd) {
			this->_curValue += *inputBuf++;
			*outputBuf++ = this->_curValue << this->_shift;
		}
	}

	cvt.buf = myBuf;
	cvt.len = len * cvt.len_ratio;
	SDL_ConvertAudio(&cvt);

	/* Handle fading */
	int volume = Mix_VolumeMusic(-1);
	if (this->_fading != MIX_NO_FADING) {
		if (this->_fade_step++ < this->_fade_steps) {
			int fade_step  = this->_fade_step;
			int fade_steps = this->_fade_steps;

			if (this->_fading == MIX_FADING_OUT) {
				volume = (volume * (fade_steps-fade_step)) / fade_steps;
			} else { /* Fading in */
				volume = (volume * fade_step) / fade_steps;
			}
		} else {
			if (this->_fading == MIX_FADING_OUT) {
				/* you still have to stop this yourself */
				return;
			}
			this->_fading = MIX_NO_FADING;
		}
	}

	SDL_MixAudio(buf, cvt.buf, cvt.len, volume);
}

void MusicResource_play(MusicResource* this, int ms) {
	if (ms > 0) {
		this->_fading = MIX_FADING_IN;
		this->_fade_step = 0;
		this->_fade_steps = ms / msPerStep;
	} else {
		this->_fading = MIX_NO_FADING;
	}

	Mix_HookMusic(MusicResource_player, (void*)this);
}

void MusicResource_fadeOut(int ms) {
	MusicResource* this = Mix_GetMusicHookData();

	if (ms <= 0) {  /* just halt immediately. */
		MusicResource_stop();
		return;
	}

	if (this) {
		SDL_LockAudio();

		int fade_steps = (ms + msPerStep - 1) / msPerStep;
		if ( this->_fading == MIX_NO_FADING ) {
			this->_fade_step = 0;
		} else {
			int step;
			int old_fade_steps = this->_fade_steps;
			if ( this->_fading == MIX_FADING_OUT ) {
				step = this->_fade_step;
			} else {
				step = old_fade_steps - this->_fade_step + 1;
			}
			this->_fade_step = (step * fade_steps) / old_fade_steps;
		}
		this->_fading = MIX_FADING_OUT;
		this->_fade_steps = fade_steps;

		SDL_UnlockAudio();
	}
}

static void MusicResource_initializer(void* udata, Uint8* buf, int len) {
	if(len <= 0) {
		printf("Error: audio opened with no length\n");
		*(int*)udata = 0;
	}
	else {
		*(int*)udata = len;
	}
}

void MusicResource_init() {
	if (myBuf)
		return;

	int len = -1;
	Mix_HookMusic(MusicResource_initializer, &len);
	while (1) {
		SDL_Delay(1); /* Wait one tick */
		if (len >= 0) break;
	}
	Mix_HookMusic(NULL, NULL);

	int dst_rate, dst_channels;
	Uint16 dst_format;
	Mix_QuerySpec(&dst_rate, &dst_format, &dst_channels);
	SDL_BuildAudioCVT(&cvt, AUDIO_S16LSB, 1, 22050, dst_format, dst_channels, dst_rate);

	myBuf = safemalloc(len * cvt.len_mult);

	msPerStep = (int)(((double)len * 1000.0 / 2) / dst_rate);
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
Neverhood_MusicResource_stop(CLASS)
		const char* CLASS
	CODE:
		MusicResource_stop();

void
Neverhood_MusicResource_play(THIS, ms)
		MusicResource* THIS
		int ms
	CODE:
		MusicResource_play(THIS, ms);

void
Neverhood_MusicResource_init(CLASS)
		const char* CLASS
	CODE:
		MusicResource_init();

void
Neverhood_MusicResource_fade_out(CLASS, ms)
		const char* CLASS
		int ms
	CODE:
		MusicResource_fadeOut(ms);
