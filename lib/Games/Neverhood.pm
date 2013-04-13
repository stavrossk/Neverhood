=head1 NAME

Neverhood - An engine for The Neverhood in SDL Perl

=head1 AUTHOR

Blaise Roth <blaizer@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Blaise Roth

This is free software; you can redistribute and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

$Neverhood::VERSION = 0.22;

use Neverhood::Base;

use Neverhood::Options;
use Neverhood::ResourceKey;
use Neverhood::Draw;
use Neverhood::Tick;
use Neverhood::ResourceMan;
use Neverhood::Scene;
use Neverhood::Sprite;
use Neverhood::Sequence;
use Neverhood::MoviePlayer;

use Neverhood::Scene::Test;

class Neverhood {
	use SDL::Constants ':SDL::Events';

	pvt_arg options => 'Neverhood::Options', required;

	rpvt scene        => 'Neverhood::Scene';
	rpvt prev_scene   => Maybe['Neverhood::Scene'];
	rpvt app          => Maybe[Surface];
	rpvt resource_man => 'Neverhood::ResourceMan';

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

		$self->_set_resource_man(Neverhood::ResourceMan->new());

		Neverhood::SoundResource::init();
		Neverhood::MusicResource::init();

		if ($self->_options->mute) {
			SDL::Mixer::Music::volume_music(0);
			SDL::Mixer::Channels::volume(-1, 0);
		}

		while ($self->app->stopped ne 1) {
			Neverhood::Draw->invalidate_all();
			if ($self->scene) {
				$prev_scene = ref $self->scene;
				$prev_scene =~ s/^Neverhood:://;
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
	method load_new_scene (SceneName|Neverhood::Scene $scene_name, SceneName $prev_scene_name) {
		debug("Scene: %s; Previous scene: %s", $scene_name, $prev_scene_name);

		if (ref $scene_name) {
			$self->_set_scene($scene_name);
			return;
		}

		$scene_name = "Neverhood::Scene::$scene_name";
		if (!is_class_loaded $scene_name) {
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
					and !$scene->isa('Neverhood::CutScene') and !$prev_scene->isa('Neverhood::CutScene')) {
				$scene->set_prev_music($prev_scene->prev_music);
			}
		}

		$self->_set_scene($scene);

		if ($scene->isa('Neverhood::MenuScene')) {
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
			if ($e->type == SDL_ACTIVEEVENT) {
				if ($e->active_state & SDL_APPINPUTFOCUS) {
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
			if ($e->type == SDL_KEYDOWN) {
				if ($e->key_sym == SDLK_LALT) {
					$lalt = 1;
				}
				elsif ($e->key_sym == SDLK_RALT) {
					$ralt = 1;
				}
				else {
					undef $lalt;
					undef $ralt;
				}
			}
			elsif ($e->type == SDL_KEYUP and $e->key_sym == SDLK_LALT && $lalt || $e->key_sym == SDLK_RALT && $ralt) {
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

				Neverhood::Draw->update_screen();
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
				unless (defined $app->stopped and $app->stopped eq 1) {
					SDL::Mixer::Channels::resume(-1);
					SDL::Mixer::Music::resume_music();
				}
			},
		));

		$self->app->draw_rect(undef, 0x000000FF);
		$self->app->update();
	}

}
