/*
// SoundResource - decodes BLBSFX sounds and loads them as MixChunks
// Based on http://wiki.multimedia.cx/index.php?title=BLB
*/

#ifndef __SOUND_RESOURCE__
#define __SOUND_RESOURCE__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <ResourceEntry.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

typedef Mix_Chunk SoundResource;
/*	int allocated;
	Uint8* abuf;
	Uint32 alen;
	Uint8 volume;
} Mix_Chunk; */

#define SOUND_CHANNELS 8

SoundResource* SoundResource_new (ResourceEntry* entry);
Uint32 SoundResource_play (SoundResource* this, int loops);
void SoundResource_stop (SoundResource* this, Uint32 id);
bool SoundResource_isPlaying (SoundResource* this, Uint32 id);
void SoundResource_init ();
void SoundResource_destroy (SoundResource* this);

static int channels;

static SDL_AudioCVT* cvt;

static Uint32 current_id;
static Uint32 playing_ids[SOUND_CHANNELS];

SoundResource* SoundResource_new (ResourceEntry* entry)
{
	SoundResource* this = (SoundResource*)safemalloc(sizeof(SoundResource));

	if (entry->type != 7)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	if (!cvt) {
		cvt = (SDL_AudioCVT*)safemalloc(sizeof(SDL_AudioCVT));
		SDL_BuildSpecAudioCVT(cvt, AUDIO_S16LSB, 1, 22050);
		if (cvt->len_mult != 1 || cvt->len_ratio != 1)
			error("Obtained audio did not meet minimum requirements");
	}

	this->allocated = 1;
	this->volume = MIX_MAX_VOLUME;

	Uint32 input_size = entry->size;
	Uint8* input = ResourceEntry_getBuffer(entry);
	Uint8 ext_data[1];
	ResourceEntry_getExtData(entry, ext_data, 1);
	Uint8 shift = *ext_data;

	if (shift == 0xFF) { /* uncompressed PCM */
		this->alen = input_size;
		this->abuf = input;
	}
	else { /* DW ADPCM compressed */
		this->alen = input_size * 2;
		this->abuf = (Uint8*)safemalloc(this->alen);

		Sint8* input_buf = (Sint8*)input;
		Sint8* input_end = input_buf + input_size;

		Sint16 cur_value = 0;
		Sint16* output_buf = (Sint16*)this->abuf;
		while (input_buf < input_end) {
			cur_value += *input_buf++;
			*output_buf++ = cur_value << shift;
		}

		safefree(input);
	}

	cvt->buf = this->abuf;
	cvt->len = this->alen;
	SDL_ConvertAudio(cvt);

	return this;
}

Uint32 SoundResource_play (SoundResource* this, int loops)
{
	SDL_LockAudio();
	int channel = Mix_PlayChannel(-1, this, loops);
	if (channel >= 0) {
		playing_ids[channel] = ++current_id;
	}
	SDL_UnlockAudio();

	return current_id;
}

void SoundResource_stop (SoundResource* this, Uint32 id)
{
	int i;
	for (i = 0; i < channels; i++) {
		if (id == playing_ids[i] && this == Mix_GetChunk(i)) {
			Mix_HaltChannel(i);
			playing_ids[i] = 0;
			break;
		}
	}
}

static void SoundResource_finished (int channel) {
	playing_ids[channel] = 0;
}

bool SoundResource_isPlaying (SoundResource* this, Uint32 id)
{
	int i;
	for (i = 0; i < channels; i++) {
		if (id == playing_ids[i] && this == Mix_GetChunk(i)) {
			return 1;
		}
	}
	return 0;
}

void SoundResource_init ()
{
	int want_frequency = 22050, want_format = AUDIO_S16SYS, want_channels = 1, want_chunk_size = 256;
	Mix_OpenAudio(want_frequency, want_format, want_channels, want_chunk_size);

	int got_frequency, got_channels;
	Uint16 got_format;
	int status = Mix_QuerySpec(&got_frequency, &got_format, &got_channels);

	if (status <= 0 || got_frequency <= 0 || got_format <= 0 || got_channels <= 0)
		error("Audio did not open correctly");

	Mix_AllocateChannels(SOUND_CHANNELS);
	channels = Mix_AllocateChannels(-1);
	if (channels <= 0)
		error("Mixer could not allocate any channels");

	Mix_ChannelFinished(SoundResource_finished);
}

void SoundResource_destroy (SoundResource* this)
{
	int i;
	for (i = 0; i < channels; i++) {
		if (this == Mix_GetChunk(i)) {
			Mix_HaltChannel(i);
			playing_ids[i] = 0;
		}
	}

	this->allocated = 1;
	Mix_FreeChunk(this);
}

#endif
