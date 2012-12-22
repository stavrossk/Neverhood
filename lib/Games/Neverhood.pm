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

use 5.01;
use MooseX::Declare;
use Method::Signatures::Modifiers;
use Games::Neverhood::Moose;

use Games::Neverhood::Options;
use Games::Neverhood::Drawable;
use Games::Neverhood::ResourceMan;
use Games::Neverhood::MoviePlayer;
use Games::Neverhood::Sprite;

class Games::Neverhood {
	use SDL::Constants ':SDL::Events', ':SDL::Audio';

	my ($player, $sprite, $sprite_on_top, $sequence);

	has scene    => private_set 'Games::Neverhood::Scene';
	has app      => private_set Maybe(Surface);
	has _options => ro 'Games::Neverhood::Options', init_arg => 'options', required => 1;
	has resource_man => private_set 'Games::Neverhood::ResourceMan';

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
		
		$self->resource_man(Games::Neverhood::ResourceMan->new());

		$player = Games::Neverhood::MoviePlayer->new(file => '40800711');
		# $player = Games::Neverhood::MoviePlayer->new(file => '210C2009');
		debug("Playing video %s\nframe rate: %f; frame count: %d; is double size: %s",
				$player->file, $player->frame_rate, $player->frame_count, ($player->is_double_size ? 'yes' : 'no'));
				
		my $palette = $self->resource_man->get_palette('92CA2C9B');

		$sprite        = Games::Neverhood::Sprite->new(file => '4086520E');
		$sprite_on_top = Games::Neverhood::Sprite->new(file => '809861A6');
		Games::Neverhood::SurfaceUtil::set_palette($sprite_on_top->_surface, $sprite->_surface->format->palette);
		# Games::Neverhood::SurfaceUtil::set_palette($sprite_on_top->_surface, $palette);
		Games::Neverhood::SurfaceUtil::set_color_keying($sprite_on_top->_surface, 1);
		
		$sequence = $self->resource_man->get_sequence('022C90D4');

		Games::Neverhood::SoundResource::init();
		Games::Neverhood::MusicResource::init();
		
		if ($self->_options->mute) {
			SDL::Mixer::Music::volume_music(0);
			SDL::Mixer::Channels::volume(-1, 0);
		}
		
		my $music = $self->resource_man->get_music('00103144');
		$music->play(0);
		$music->fade_out(30_000);
		
		# my $sound = $self->resource_man->get_sound('ED403E03'); # compressed
		my $sound = $self->resource_man->get_sound('CD4F8411'); # uncompressed
		my $id = $sound->play(0);

		while($self->app->stopped ne 1) {
			Games::Neverhood::Drawable->invalidate_all();
			if($self->scene) {
				$prev_scene = ref $self->scene;
				$prev_scene =~ s/^Games::Neverhood:://;
			}
			$self->load_new_scene($self->app->stopped, $prev_scene);
			$self->app->run();
		}
		
		say '=' x 69 if debug();

		$self->app(undef);
		undef $self;
		undef $;;
	}

	# called outside of the run loop to load a new scene
	method load_new_scene (SceneName $scene, SceneName $prev_scene) {
		debug("Scene: %s; Previous scene: %s", $scene, $prev_scene);
	}

	method init_app () {
		return if $self->app;
		
		SDLx::App->init(['video']);
		Games::Neverhood::SurfaceUtil::set_icon(share_file('icon.bmp'), SDL::Color->new(255, 0, 255));

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

		$self->app(SDLx::App->new(
			title      => 'The Neverhood',
			width      => 640,
			height     => 480,
			depth      => 16,
			dt         => 1 / 10,
			max_t      => 1 / 10,
			min_t      => $self->_options->fps_limit &&  1 / $self->_options->fps_limit,
			delay      => 0,
			eoq        => 1,
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

			# icon => share_file('icon.bmp'),
			# icon_alpha_key => SDL::Color->new(255, 0, 255),

			event_handlers => [
				$event_window_pause,
				$event_pause,
				sub{},
			],
			show_handler => sub {
				my ($time, $app) = @_;

				# move

				$player->advance_in_time($time);
				$player->invalidate_all() if $player->is_invalidated;

				# show

				$app->draw_rect([0, 0, $app->w, $app->h], [255, 255, 255, 255]) if debug();

				# $sprite->draw();
				
				$player->draw() if $player->is_invalidated;
				
				my $frame = $sequence->get_frame_surface(2);
				Games::Neverhood::SurfaceUtil::set_color_keying($frame, 1);
				SDL::Video::blit_surface($frame, undef, $;->app, SDL::Rect->new(380, 109, 0, 0));
				
				$sprite_on_top->draw();

				Games::Neverhood::Drawable->update_screen();
			},
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

		$self->app->draw_rect([0, 0, $self->app->w, $self->app->h], [0, 0, 0, 255]);
		$self->app->update();
	}

}

1;
