# the game object -- contains the current scene and game globals and sets up the App
use 5.01;
package Games::Neverhood;
use Mouse;

$Games::Neverhood::VERSION = 0.010;

use SDL;
use SDLx::App;
use SDL::Video;
use SDL::Rect;
use SDL::Color;
use SDL::Events;

use File::Spec;

use Games::Neverhood::SmackerPlayer;

# globals from bin/nhc
our ($DataDir, $Debug, $FPSLimit, $Fullscreen, $NoFrame, $ShareDir, $StartingScene, $StartingPrevScene);
BEGIN {
#	$Debug;
	$DataDir           //= File::Spec->catdir('DATA');
	$FPSLimit          //= 60;
	$Fullscreen        //= 1;
	$NoFrame           //= 1;
	$ShareDir          //= do { require File::ShareDir; File::ShareDir::dist_dir('Games-Neverhood') };
	$StartingScene     //= 'Scene::Nursery::One';
	$StartingPrevScene //= $Games::Neverhood::StartingScene;
}

my $player;

sub BUILD {
	$; = shift;
	
	printf <<GREETING, $DataDir, $ShareDir, '=' x 50;
Games::Neverhood started
 Data dir:  %s
Share dir:  %s
%s
GREETING

	$player = Games::Neverhood::SmackerPlayer->new(file => 'a', pos => [2, 20]);
}

# the SDLx::App
sub app {
	state $app = do {
		my ($event_window_pause, $event_pause);
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

		Games::Neverhood::App->new(
			title      => 'The Neverhood',
			width      => 640,
			height     => 480,
			depth      => 16,
			min_t      => $FPSLimit && 1 / $FPSLimit,
			delay      => $FPSLimit && (1 / $FPSLimit)/4,
			eoq        => 1,
			init       => ['video', 'audio'],
			no_cursor  => 1,
			centered   => 1,
			fullscreen => $Fullscreen,
			no_frame   => $NoFrame,
			hw_surface => 1, double_buf => 1,
#			sw_surface => 1,
#			any_format => 1,
#			async_blit => 1,
#			hw_palette => 1,

			icon => $;->share_file('icon.bmp'),
			icon_alpha_key => SDL::Color->new(255, 255, 255),

			event_handlers => [
				$event_window_pause,
				$event_pause,
				sub{},
			],
			move_handlers => [
				sub{},
			],
			show_handlers => [
				sub{SDL::Video::fill_rect(
					$_[1],
					SDL::Rect->new(0, 0, 640, 480),
					SDL::Video::map_RGBA($_[1]->format, 23, 156, 56, 255)
				)},
				sub{$player->draw},
				sub{$_[1]->flip},
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
	};
}

sub debug {
	return $Debug if @_ <= 1;
	&_msg if $Debug;
}
sub error {
	&_msg;
	exit 1;
}
sub _msg {
	shift;
	my @caller = caller 2;
	$caller[3] =~ s/^$caller[0]:://;
	$caller[1] =~ s/^$ShareDir/.../;
	say STDERR sprintf "%s::%s: %s at %s line %d", @caller[0, 3], sprintf(shift, @_), @caller[1, 2];
	return;
}

sub data_file {
	shift; return File::Spec->catfile($DataDir, @_);
}
sub data_dir {
	shift; return File::Spec->catdir($DataDir, @_);
}
sub share_file {
	shift; return File::Spec->catfile($ShareDir, @_);
}
sub share_dir {
	shift; return File::Spec->catdir($ShareDir, @_);
}

no Mouse;
__PACKAGE__->meta->make_immutable;

package Games::Neverhood::App;

our @ISA = qw/SDLx::App/;

sub pause {
	my $self = shift;
	
	# stuff before pause
	
	$self->SUPER::pause(@_);
	
	# stuff after pause
}

1;
