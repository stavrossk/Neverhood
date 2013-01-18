=head1 NAME

Games::Neverhood - The Neverhood remade in SDL Perl

=head1 AUTHOR

Blaise Roth <blaizer@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012 Blaise Roth

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

$Games::Neverhood::VERSION = 0.20;

use MooseX::Declare;
use Method::Signatures::Modifiers;
use Games::Neverhood::Exports ();

use Games::Neverhood::Options;
use Games::Neverhood::Draw;
use Games::Neverhood::Tick;
use Games::Neverhood::ResourceMan;
use Games::Neverhood::Scene;
use Games::Neverhood::Sprite;
use Games::Neverhood::Sequence;
use Games::Neverhood::MoviePlayer;

use Games::Neverhood::Scene::Test;

class Games::Neverhood {
	use SDL::Constants ':SDL::Events';

	pvt_arg options => 'Games::Neverhood::Options', required;

	rpvt scene        => 'Games::Neverhood::Scene';
	rpvt prev_scene   => Maybe['Games::Neverhood::Scene'];
	rpvt app          => Maybe[Surface];
	rpvt resource_man => 'Games::Neverhood::ResourceMan';

	method BUILD (@_) { $; = $self }

	method run (SceneName $scene, SceneName $prev_scene) {
		printf unindent(<<'		HELLO'), data_dir(), share_dir();
		 Data dir: %s
		Share dir: %s
		HELLO

		say '=' x 69 if debug();

		# app stop is used to hold the scene name to be set
		$self->init_app();
		$self->app->stop($scene);

		$self->_set_resource_man(Games::Neverhood::ResourceMan->new());

		Games::Neverhood::SoundResource::init();
		Games::Neverhood::MusicResource::init();

		if ($self->_options->mute) {
			SDL::Mixer::Music::volume_music(0);
			SDL::Mixer::Channels::volume(-1, 0);
		}

		while($self->app->stopped ne 1) {
			Games::Neverhood::Draw->invalidate_all();
			if($self->scene) {
				$prev_scene = ref $self->scene;
				$prev_scene =~ s/^Games::Neverhood:://;
			}
			$self->load_new_scene($self->app->stopped, $prev_scene);
			$self->app->run();
		}

		say '=' x 69 if debug();

		$self->_set_app(undef);
		undef $self;
		undef $;;
	}

	# called outside of the run loop to load a new scene
	method load_new_scene (SceneName|Games::Neverhood::Scene $scene_name, SceneName $prev_scene_name) {
		debug("Scene: %s; Previous scene: %s", $scene_name, $prev_scene_name);

		if (ref $scene_name) {
			$self->_set_scene($scene_name);
			return;
		}

		$scene_name = "Games::Neverhood::Scene::$scene_name";
		unless (is_class_loaded $scene_name) {
			error("$scene_name is not loaded");
		}
		my $scene = $scene_name->new;
		my $prev_scene = $self->scene;

		if ($prev_scene) {
			my $scene_music = $scene->music;
			my $prev_scene_music = $prev_scene->music;
			my $bad;
			if ($scene_music) {
				if ($prev_scene_music) {
					if ($scene_music != $prev_scene_music) {
						$bad = 1;
						$prev_scene_music->fade_out(0);
						$scene_music->fade_in(0);
					}
				}
				else {
					$scene_music->fade_in(2_000);
				}
			}
			elsif ($prev_scene_music) {
				$prev_scene_music->fade_out(2_000);
				$scene->set_prev_music($prev_scene_music);
			}

			if (!$scene->prev_music and $prev_scene->prev_music and !$bad
					and !$scene->isa('Games::Neverhood::CutScene') and !$prev_scene->isa('Games::Neverhood::CutScene')) {
				$scene->set_prev_music($prev_scene->prev_music);
			}
		}

		$self->_set_scene($scene);

		if ($scene->isa('Games::Neverhood::MenuScene')) {
			$scene->setup($prev_scene);
		}
		else {
			$scene->setup($prev_scene_name);
		}
	}

	method init_app () {
		return if $self->app;

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
			$self->_options->fullscreen;
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

		$self->_set_app(SDLx::App->new(
			title      => 'The Neverhood',
			width      => 640,
			height     => 480,
			depth      => 16,
			dt         => 1 / 10,
			max_t      => 1 / 10,
			min_t      => $self->_options->fps_limit &&  1 / $self->_options->fps_limit,
			delay      => 0,
			init       => ['audio'],
			no_cursor  => 1,
			centered   => 1,
			fullscreen => $self->_options->fullscreen,
			no_frame   => $self->_options->no_frame,
			grab_input => $self->_options->grab_input,
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
			show_handler => sub {
				my ($time, $app) = @_;

				# move

				$;->scene->handle_time($time);

				# show

				$app->draw_rect(undef, 0xFF00FFFF) if debug;

				$;->scene->draw();

				Games::Neverhood::Draw->update_screen();
			},
			move_handler => undef,
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
				my ($app) = @_;
				SDL::Mixer::Channels::pause(-1);
				SDL::Mixer::Music::pause_music();
			},
			after_pause => sub {
				my ($app) = @_;
				unless(defined $app->stopped and $app->stopped eq 1) {
					SDL::Mixer::Channels::resume(-1);
					SDL::Mixer::Music::resume_music();
				}
			},
		));

		$self->app->draw_rect(undef, 0x000000FF);
		$self->app->update();
	}

}
