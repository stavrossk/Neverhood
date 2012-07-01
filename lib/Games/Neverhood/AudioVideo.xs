/*
// AudioVideo - Miscellaneous audio/video things that are better written in C, but called from Perl
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <resource.h>
#include <SDL/SDL.h>

SDL_Surface* AudioVideo_mirrorSurface(SDL_Surface* surface)
{
	SDL_Surface* mirrored_surface = SDL_ConvertSurface(surface, surface->format, surface->flags);

	Uint8* pixels = surface->pixels;
	Uint8* mirrored_pixels = mirrored_surface->pixels;
	Uint8* pixels_end = pixels + surface->h * surface->pitch;

	Uint16 off = surface->w - 1;
	Uint16 x;
	while (pixels < pixels_end) {
		for (x = 0; x < surface->w; x++)
			mirrored_pixels[x] = pixels[off - x];

		pixels += surface->pitch;
		mirrored_pixels += surface->pitch;
	}

	return mirrored_surface;
}

void AudioVideo_initAudio() {
	int wantFrequency = 22050, wantFormat = AUDIO_S16SYS, wantChannels = 1, wantChunkSize = 256;
	Mix_OpenAudio(wantFrequency, wantFormat, wantChannels, wantChunkSize);

	int gotFrequency, gotChannels;
	Uint16 gotFormat;
	int status = Mix_QuerySpec(&gotFrequency, &gotFormat, &gotChannels);

	if(status <= 0 || gotFrequency <= 0 || gotFormat <= 0 || gotChannels <= 0)
		error("Audio did not open correctly");

	Mix_AllocateChannels(SOUND_CHANNELS);
	if(Mix_AllocateChannels(-1) <= 0)
		error("Mixer could not allocate any channels");
}

MODULE = Games::Neverhood::AudioVideo		PACKAGE = Games::Neverhood::AudioVideo		PREFIX = Neverhood_AudioVideo_

SDL_Surface*
Neverhood_AudioVideo_mirror_surface(surface)
		SDL_Surface* surface
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = AudioVideo_mirrorSurface(surface);
	OUTPUT:
		RETVAL

void
Neverhood_AudioVideo_init_audio()
	CODE:
		AudioVideo_initAudio();
