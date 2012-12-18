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
#include <audio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

void AudioVideo_initAudio ()
{
	int want_frequency = 22050, want_format = AUDIO_S16SYS, want_channels = 1, want_chunk_size = 256;
	Mix_OpenAudio(want_frequency, want_format, want_channels, want_chunk_size);

	int got_frequency, got_channels;
	Uint16 got_format;
	int status = Mix_QuerySpec(&got_frequency, &got_format, &got_channels);

	if (status <= 0 || got_frequency <= 0 || got_format <= 0 || got_channels <= 0)
		error("Audio did not open correctly");

	Mix_AllocateChannels(SOUND_CHANNELS);
	if (Mix_AllocateChannels(-1) <= 0)
		error("Mixer could not allocate any channels");
}

MODULE = Games::Neverhood::AudioVideo		PACKAGE = Games::Neverhood::AudioVideo		PREFIX = Neverhood_AudioVideo_

void
Neverhood_AudioVideo_init_audio ()
	CODE:
		AudioVideo_initAudio();
