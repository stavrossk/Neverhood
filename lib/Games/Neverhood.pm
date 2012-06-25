# Games::Neverhood - The Neverhood remade in SDL Perl
# Copyright (C) 2012  Blaise Roth
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

use 5.01;
package Games::Neverhood;
use Games::Neverhood::Moose;

$Games::Neverhood::VERSION = 0.10;

use SDL::Events;
use SDL::Mixer;

use XSLoader;

use Games::Neverhood::MoviePlayer;
use Games::Neverhood::Sprite;

BEGIN {
	XSLoader::load('Games::Neverhood::SmackerResource');
	XSLoader::load('Games::Neverhood::SpriteResource');
	XSLoader::load('Games::Neverhood::AudioVideo');
	XSLoader::load('Games::Neverhood::SoundResource');
	XSLoader::load('Games::Neverhood::MusicResource');
}

# globals from bin/nhc
our ($Data_Dir, $Debug, $FPS_Limit, $Fullscreen, $Grab_Input, $No_Frame, $Share_Dir, $Starting_Scene, $Starting_Prev_Scene);
BEGIN {
	$Debug          //= 0;
	$Data_Dir       //= File::Spec->catdir('DATA');
	$FPS_Limit      //= 60;
	$Fullscreen     //= 0;
	$No_Frame       //= 0;
	$Share_Dir      //= do { require File::ShareDir; File::ShareDir::dist_dir('Games-Neverhood') };
	$Starting_Scene //= 'Scene::Nursery::One';

	$Grab_Input          //= $No_Frame || $Fullscreen;
	$Starting_Prev_Scene //= $Games::Neverhood::StartingScene;
}

our $App;

private_set scene =>
	isa => 'Games::Neverhood::Scene',
;

my $player;
my $sprite;

sub BUILD { $; = shift }

sub run {
	my ($self, $scene, $prev_scene) = @_;

	printf <<HELLO, $Data_Dir, $Share_Dir, '=' x 69;

Games::Neverhood started
 Data dir:  %s
Share dir:  %s
%s
HELLO

	$scene //= 'Scene::Nursery::One';
	$prev_scene //= $scene;

	# app stop is used to hold the scene name to be set
	$self->init_app();
	$self->app->stop($scene);
	
	Games::Neverhood::Drawable->invalidate_all();

	$player = Games::Neverhood::MoviePlayer->new(file => share_file('m', '0.0A'));
	debug("Playing video %s\nframe rate: %f; frame count: %d; is double size: %s",
			$player->file, $player->frame_rate, $player->frame_count, ($player->is_double_size ? 'yes' : 'no'));

	# $sprite = Games::Neverhood::Sprite->new(file => share_file('i', '496.02'));

	# my $sound_stream = SDL::RWOps->new_file(share_file('a', '11.07'), 'r') // error(SDL::get_error());
	# my $sound = Games::Neverhood::SoundResource->new($sound_stream);
	# $sound->play(-1);

	# my $music_stream = SDL::RWOps->new_file(share_file('a', '132.08'), 'r') // error(SDL::get_error());
	# my $music = Games::Neverhood::MusicResource->new($music_stream);
	# $music->play();

	# my $music_stream = SDL::RWOps->new_file(share_file('a', '132.08'), 'r') // error(SDL::get_error());
	# my $music = Games::Neverhood::SoundResource->new($music_stream);
	# $music->play(-1);

	while($self->app->stopped ne 1) {
		if($self->scene) {
			$prev_scene = ref $self->scene;
			$prev_scene =~ s/^Games::Neverhood:://;
		}
		$self->load_new_scene($self->app->stopped, $prev_scene);
		$self->app->run();
	}

	undef $self;
	undef $;;
	undef $App;

	printf <<GOODBYE, '=' x 69
%s
Games::Neverhood ended normally

GOODBYE
}

# called outside of the run loop to load a new scene
sub load_new_scene {
	my ($self, $scene, $prev_scene) = @_;
	debug("Scene: %s; Previous scene: %s", $scene, $prev_scene);
}

# the SDLx::App
sub app { $App }
sub init_app {
	return if $App;

	my ($event_window_pause, $event_pause); # recursive subs
	$event_window_pause = sub {
		# pause when the app loses focus
		my ($e, $app) = @_;
		if($e->type == SDL_ACTIVEEVENT) {
			if($e->active_state & SDL_APPINPUTFOCUS) {
				return 1 if $e->active_gain;
				$app->pause($event_window_pause);
			}
		}
		# if we're fullscreen we should unpause no matter what event we get
		$Fullscreen;
	};
	$event_pause = sub {
		# toggle pause when either alt is pressed
		my ($e, $app) = @_;
		state $lalt;
		state $ralt;
		if($e->type == SDL_KEYDOWN) {
			if($e->key_sym == SDLK_LALT) {
				$lalt = 1;
			}
			elsif($e->key_sym == SDLK_RALT) {
				$ralt = 1;
			}
			else {
				undef $lalt;
				undef $ralt;
			}
		}
		elsif($e->type == SDL_KEYUP and $e->key_sym == SDLK_LALT && $lalt || $e->key_sym == SDLK_RALT && $ralt) {
			undef($e->key_sym == SDLK_LALT ? $lalt : $ralt);
			return 1 if $app->paused;
			$app->pause($event_pause);
		}
		return;
	};

	$App = SDLx::App->new(
		title      => 'The Neverhood',
		width      => 640,
		height     => 480,
		depth      => 16,
		dt         => 1 / 10,
		max_t      => 1 / 10,
		min_t      => $FPS_Limit &&  1 / $FPS_Limit,
		delay      => 0,
		eoq        => 1,
		init       => ['video', 'audio'],
		no_cursor  => 1,
		centered   => 1,
		fullscreen => $Fullscreen,
		no_frame   => $No_Frame,
		grab_input => $Grab_Input,
		hw_surface => 1,
#		double_buf => 1,
#		sw_surface => 1,
		any_format => 1,
#		async_blit => 1,
#		hw_palette => 1,

		icon => share_file('icon.bmp'),
		icon_alpha_key => SDL::Color->new(255, 0, 255),

		event_handlers => [
			$event_window_pause,
			$event_pause,
			sub{},
		],
		show_handlers => [sub {
			my ($time, $app) = @_;
			$player->advance_in_time($time);
			$player->invalidate_all() if $player->is_invalidated;
			
			SDL::Video::fill_rect(
				$_[1],
				SDL::Rect->new(0, 0, 640, 480),
				SDL::Video::map_RGBA($_[1]->format, 255, 255, 255, 255)
			) if debug();

			$player->draw() if $player->is_invalidated;
			# $sprite->draw();

			Games::Neverhood::Drawable->update_screen();
		}],
		stop_handler => sub {
			my ($e, $app) = @_;
				$app->stop()
			if
				$e->type == SDL_QUIT
				or
				$e->type == SDL_KEYDOWN and $e->key_sym == SDLK_F4
				and $e->key_mod & KMOD_ALT and not $e->key_mod & (KMOD_CTRL | KMOD_SHIFT | KMOD_META)
			;
		},
		before_pause => sub {
			my $app = shift;
			SDL::Mixer::Channels::pause(-1);
			SDL::Mixer::Music::pause_music();
		},
		after_pause => sub {
			my $app = shift;
			unless(defined $app->stopped and $app->stopped eq 1) {
				SDL::Mixer::Channels::resume(-1);
				SDL::Mixer::Music::resume_music();
			}
		},
	);

	my ($want_frequency, $want_format, $want_channels) = (22050, AUDIO_S16SYS, 1);
	SDL::Mixer::open_audio($want_frequency, $want_format, $want_channels, 256);

	my ($status, $got_frequency, $got_format, $got_channels) = @{SDL::Mixer::query_spec()};
	unless($status > 0 and $got_frequency == $want_frequency and $got_format !~~ [AUDIO_U8, AUDIO_S8] and $got_channels == $want_channels) {
		error("Could not get the desired audio:\n\t got: frequency=>%d, format=>0x%04X, channels=>%d\n\twant: frequency=>%d, format=>0x%04X, channels=>%d\n",
				$got_frequency, $got_format, $got_channels, $want_frequency, $want_format, $want_channels);
	}

	SDL::Mixer::Channels::allocate_channels(8);
	if(SDL::Mixer::Channels::allocate_channels(-1) <= 0) {
		error("Mixer could not allocate any channels");
	}
}

no Games::Neverhood::Moose;
__PACKAGE__->meta->make_immutable;
1;
