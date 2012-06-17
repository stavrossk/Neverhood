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
use Mouse;

$Games::Neverhood::VERSION = 0.10;

use SDL;
use SDLx::App;
use SDL::Video;
use SDL::Rect;
use SDL::Color;
use SDL::Events;
use SDL::Mixer;
use SDL::Mixer::Channels;
use SDL::RWOps;

use File::Spec;
use XSLoader;

use Games::Neverhood::SmackerPlayer;
use Games::Neverhood::Sprite;

BEGIN {
	XSLoader::load('Games::Neverhood::SmackerDecoder');
	XSLoader::load('Games::Neverhood::SpriteResource');
	XSLoader::load('Games::Neverhood::Video');
	XSLoader::load('Games::Neverhood::SoundResource');
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

has scene =>
	is => 'ro',
	isa => 'Games::Neverhood::Scene',
	writer => '_set_scene',
	init_arg => undef,
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

	$player = Games::Neverhood::SmackerPlayer->new(file => $;->share_file('c', '56.0A'));
	$;->debug("Playing video %s\nframe rate: %f; frame count: %d; is double size: %s",
			$player->file, $player->frame_rate, $player->frame_count, ($player->is_double_size ? 'yes' : 'no'));
	
	$sprite = Games::Neverhood::Sprite->new(file => $;->share_file('i', '496.02'));
	
	my $sound_stream = SDL::RWOps->new_file($;->share_file('a', '11.07'), 'r') // $;->error(SDL::get_error());
	my $sound = Games::Neverhood::SoundResource->new($sound_stream);
	$sound->inc_refcount();
	$sound->inc_refcount();
	$sound->play(0);

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
	$;->debug("Scene: %s; Previous scene: %s", $scene, $prev_scene);
}

# the SDLx::App
sub app { $App }
sub init_app {
	return if $App;
	
	my ($event_window_pause, $event_pause); # recursive subs
	$event_window_pause = sub {
		# pause when the app loses focus
		my ($e) = @_;
		if($e->type == SDL_ACTIVEEVENT) {
			if($e->active_state & SDL_APPINPUTFOCUS) {
				return 1 if $e->active_gain;
				$;->pause($event_window_pause);
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
			$;->pause($event_pause);
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

		icon => $;->share_file('icon.bmp'),
		icon_alpha_key => SDL::Color->new(255, 255, 255),

		event_handlers => [
			$event_window_pause,
			$event_pause,
			sub{},
		],
		move_handlers => [
			sub {
				my ($time, $app) = @_;
				$time *= $app->dt; # time = step * dt
				$player->advance_in_time($time);
				# $player->next_frame();
				$player->invalidate_all() if $player->is_invalidated;
			},
		],
		show_handlers => [
			sub{SDL::Video::fill_rect(
				$_[1],
				SDL::Rect->new(0, 0, 640, 480),
				SDL::Video::map_RGBA($_[1]->format, 255, 255, 255, 255)
			)},
			sub {
				$player->draw() if $player->is_invalidated;
				# $sprite->draw();
			},
			sub { Games::Neverhood::Drawable->update_screen() },
		],
		stop_handler => sub {
			my ($e, $self) = @_;
				$self->stop
			if
				$e->type == SDL_QUIT
				or
				$e->type == SDL_KEYDOWN and $e->key_sym == SDLK_F4
				and $e->key_mod & KMOD_ALT and not $e->key_mod & (KMOD_CTRL | KMOD_SHIFT | KMOD_META)
			;
		}
	);

	SDL::Mixer::open_audio(22050, AUDIO_S16SYS, 1, 1024);
	SDL::Mixer::Channels::allocate_channels(8);
}

sub pause {
	my $self = shift;

	# stuff before pause

	$self->app->pause(@_);

	# stuff after pause
}

sub debug {
	return $Debug if @_ <= 1;
	return unless $Debug;
	shift;

	my ($sub, $filename, $line) = _get_sub_filename_line();

	say STDERR sprintf "----- at %s(), %s line %d:", $sub, $filename, $line;
	say STDERR sprintf(shift, @_);
	return;
}
sub error {
	shift;

	my ($sub, $filename, $line) = _get_sub_filename_line();

	say STDERR sprintf "%s at %s(), %s line %d", sprintf(shift, @_), $sub, $filename, $line;
	exit 1;
}
sub _get_sub_filename_line {
	my ($package, $filename, $line) = (caller 1);
	my ($sub)                       = (caller 2)[3];

	# removes the package name at the start of the sub name
	$sub =~ s/^\Q${package}::\E//;

	# might replace the full lib name from the filename with lib
	my $i = -1;
	1 until(++$i > $#INC or $filename =~ s/^\Q$INC[$i]\E/lib/);

	return($sub, $filename, $line);
}

sub data_file {
	shift; return File::Spec->catfile($Data_Dir, @_);
}
sub data_dir {
	shift; return File::Spec->catdir($Data_Dir, @_);
}
sub share_file {
	shift; return File::Spec->catfile($Share_Dir, @_);
}
sub share_dir {
	shift; return File::Spec->catdir($Share_Dir, @_);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
