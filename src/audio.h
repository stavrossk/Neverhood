/*
// resource.h
// functions common to audio
*/

#ifndef __AUDIO_H__
#define __AUDIO_H__

#include <helper.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

int SDL_BuildSpecAudioCVT (SDL_AudioCVT *cvt, Uint16 src_format, Uint8 src_channels, int src_rate)
{
	int dst_rate, dst_channels;
	Uint16 dst_format;
	Mix_QuerySpec(&dst_rate, &dst_format, &dst_channels);
	SDL_BuildAudioCVT(cvt, src_format, src_channels, src_rate, dst_format, dst_channels, dst_rate);
	if (cvt->len_mult <= 0 || cvt->len_ratio <= 0)
		error("Neverhood's audio can not be converted to your opened audio");
}

#endif