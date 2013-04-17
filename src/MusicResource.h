/*
// MusicResource - decodes BLBSFX music and streams it as Mixer music
// Based on http://wiki.multimedia.cx/index.php?title=BLB
*/

#ifndef __MUSIC_RESOURCE__
#define __MUSIC_RESOURCE__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <ResourceEntry.h>
#include <SmackerResource.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

typedef struct {
	Sint16 curValue;
	Uint8 shift;
	SDL_RWops* stream;
	Uint32 streamSize;
	Uint32 streamStart;
	Uint32 streamPos;

	int fading;
	int fadeStep;
	int fadeSteps;
} MusicResource;

MusicResource* MusicResource_new (ResourceEntry* entry);
void MusicResource_fadeIn (MusicResource* this, int ms);
void MusicResource_fadeOut (MusicResource* this, int ms);
void MusicResource_init ();
void MusicResource_destroy (MusicResource* this);

static MusicResource* music_playing;
static SmackerAudio* smacker_audio_playing;

static Uint8* music_buf;
static Uint8* smacker_audio_buf;

static SDL_AudioCVT cvt;

static int ms_per_step;

MusicResource* MusicResource_new (ResourceEntry* entry)
{
	MusicResource* this = safemalloc(sizeof(MusicResource));

	if (entry->type != 8)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	Uint8 ext_data[1];
	ResourceEntry_getExtData(entry, ext_data, 1);
	this->shift = *ext_data;
	if (this->shift == 0xFF)
		error("Uncompressed music resource: %08X not supported", entry->key);

	this->curValue = 0;
	this->stream = ResourceEntry_getStream(entry);
	this->streamSize = entry->size;
	this->streamStart = entry->offset;
	this->streamPos = 0;

	return this;
}

void MusicResource_fadeIn (MusicResource* this, int ms)
{
	if (ms > 0) {
		this->fading = MIX_FADING_IN;
		this->fadeStep = 0;
		this->fadeSteps = ms / ms_per_step;
	} else {
		this->fading = MIX_NO_FADING;
	}

	SDL_LockAudio();
	music_playing = this;
	SDL_UnlockAudio();
}

void MusicResource_fadeOut (MusicResource* this, int ms)
{
	if (this != music_playing) return;

	SDL_LockAudio();
	if (ms <= 0) {  /* just halt immediately. */
		music_playing = NULL;
	}
	else if (this) {
		int fade_steps = (ms + ms_per_step - 1) / ms_per_step;
		if (this->fading == MIX_NO_FADING) {
			this->fadeStep = 0;
		}
		else {
			int step;
			int old_fade_steps = this->fadeSteps;
			if (this->fading == MIX_FADING_OUT) {
				step = this->fadeStep;
			}
			else {
				step = old_fade_steps - this->fadeStep + 1;
			}
			this->fadeStep = (step * fade_steps) / old_fade_steps;
		}
		this->fading = MIX_FADING_OUT;
		this->fadeSteps = fade_steps;

	}
	SDL_UnlockAudio();
}

static void MusicResource_player_recurse (MusicResource* this, Sint16* buf, int size, Sint8* input_buf, int input_size)
{
	int remaining_size = this->streamSize - this->streamPos;
	int input_size_taken = remaining_size < input_size ? remaining_size : input_size;
	SDL_RWread(this->stream, input_buf, input_size_taken, 1);

	/* DW ADPCM compressed */
	Sint8* input_end = input_buf + input_size_taken;

	while (input_buf < input_end) {
		this->curValue += *input_buf++;
		*buf++ = this->curValue << this->shift;
	}

	this->streamPos += input_size_taken;
	remaining_size -= input_size_taken;
	size -= input_size_taken * 2;
	input_size -= input_size_taken;

	if (remaining_size <= 0) { /* loop */
		SDL_RWseek(this->stream, this->streamStart, SEEK_SET);
		this->streamPos = 0;
		this->curValue = 0;
	}

	if (size > 0)
		MusicResource_player_recurse(this, buf, size, input_buf, input_size);
}

static void MusicResource_player (void* udata, Uint8* buf, int size)
{
	memset(buf, 0, size); /* does this help? */
	if (Mix_PausedMusic())
		return;

	if (music_playing && !Mix_PausedMusic()) {
		/* DW ADPCM compressed */
		int input_size;
		Sint8* input_buf;
		input_size = size / 2.0 * cvt.len_ratio;
		input_buf = (Sint8*)music_buf + input_size;

		MusicResource_player_recurse(music_playing, (Sint16*)music_buf, size, input_buf, input_size);

		cvt.buf = music_buf;
		cvt.len = size * cvt.len_ratio;
		SDL_ConvertAudio(&cvt);

		/* Handle fading */
		int volume = Mix_VolumeMusic(-1);
		if (music_playing->fading != MIX_NO_FADING) {
			if (music_playing->fadeStep++ < music_playing->fadeSteps) {
				int fade_step  = music_playing->fadeStep;
				int fade_steps = music_playing->fadeSteps;

				if (music_playing->fading == MIX_FADING_OUT) {
					volume = (volume * (fade_steps-fade_step)) / fade_steps;
				}
				else { /* Fading in */
					volume = (volume * fade_step) / fade_steps;
				}
			}
			else {
				if (music_playing->fading == MIX_FADING_OUT) /* finished fading out */
					music_playing = NULL;
				else
					music_playing->fading = MIX_NO_FADING; /* finished fading in */
			}
		}
		SDL_MixAudio(buf, cvt.buf, cvt.len, volume);
	}

	if (smacker_audio_playing && !Mix_PausedMusic()) {
		SmackerResource_player(smacker_audio_playing, smacker_audio_buf, size);
		SDL_MixAudio(buf, smacker_audio_buf, size, Mix_VolumeMusic(-1));
	}
}

static void MusicResource_initializer (void* udata, Uint8* buf, int size)
{
	if (size <= 0) {
		printf("Error: audio opened with no size\n");
		*(int*)udata = 0;
	}
	else {
		*(int*)udata = size;
	}
}

void MusicResource_init ()
{
	if (music_buf)
		return;

	int size = -1;
	int unlocked_size;
	Mix_HookMusic(MusicResource_initializer, &size);
	do {
		SDL_Delay(1); /* Wait one tick */
		SDL_LockAudio();
		unlocked_size = size;
		SDL_UnlockAudio();
	} while (unlocked_size < 0);
	Mix_HookMusic(NULL, NULL);

	int dst_rate, dst_channels;
	Uint16 dst_format;
	Mix_QuerySpec(&dst_rate, &dst_format, &dst_channels);
	SDL_BuildAudioCVT(&cvt, AUDIO_S16LSB, 1, 22050, dst_format, dst_channels, dst_rate);

	music_buf = safemalloc(size * cvt.len_mult);
	smacker_audio_buf = safemalloc(size);

	ms_per_step = (int)(((double)size * 1000.0 / 2) / dst_rate);

	Mix_HookMusic(MusicResource_player, &smacker_audio_playing);
}

void MusicResource_destroy (MusicResource* this)
{
	MusicResource_fadeOut(this, 0);
	SDL_RWclose(this->stream);
	safefree(this);
}

#endif

