# Draw - role that standardises drawing
# Also handles "invalidating" of rects on the screen to call $app->update() minimally.
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

role Games::Neverhood::Draw {
	requires 'draw';

	my $_is_all_invalidated; # pvt Bool;
	my @_invalidated_rects;  # pvt ArrayRef(Surface);

	use constant is_visible => 1;

	rw name       => Str, default => '';
	rw visible    => Bool, default => 1;
	rw ['x', 'y'] => Int;
	ro clip_rect  => Rect;

	rpvt invalidated => Bool;
	pvt  update_rect => Maybe[Rect];

	# done manually by anything that wants to invalidate the entire screen
	method invalidate_all {
		$_is_all_invalidated = 1;
		$self->invalidate() if ref $self;
		@_invalidated_rects = ();
	}

	# done manually by a surface that wants to be invalidated
	method invalidate {
		$self->_set_invalidated(1);
	}

	method _check (Str $type, $v, $o?) {
		$self->invalidate if do {
			given ($type) {
				when ('Bool') { $v xor $o }
				when ('Str') { $v//'' ne $o//'' }
				when (['Int', 'Num']) { $v//0 != $o//0 }
				when ([Palette, Surface]) { $v//=\0; $o//=\0; $$v != $$o; }
				when (Rect) {
					$v//=SDLx::Rect->new;
					$o//=SDLx::Rect->new;
					Games::Neverhood::SurfaceUtil::RectsEqual($v, $o);
				}
				default { debug_stack("Invalidator check on unsupported type: $type"); 0 }
			}
		};
	}

	# update rects on the app
	method update_screen {
		if ($_is_all_invalidated) {
			SDL::Video::update_rect($;->app, 0, 0, 0, 0);
		}
		elsif (@_invalidated_rects) {
			SDL::Video::update_rects($;->app, @_invalidated_rects);
		}

		$_is_all_invalidated = 0;
		@_invalidated_rects = ();
	}

	around draw (@_) {
		my $update_rect = SDLx::Rect->new;
		my $old_update_rect = $self->_update_rect;
		$self->_set_update_rect($update_rect);

		my $old_clip_rect = SDLx::Rect->new;
		SDL::Video::get_clip_rect($;->app, $old_clip_rect);
		SDL::Video::set_clip_rect($;->app, $self->clip_rect) if $self->clip_rect;

		$self->$orig(@_) if $self->is_visible;

		SDL::Video::set_clip_rect($;->app, $old_clip_rect);

		if ($self->invalidated and !$_is_all_invalidated) {
			$self->_add_update_rect($old_update_rect);
		}
	}
	
	method _add_update_rect (Maybe[Rect] $old_update_rect?) {
		my $update_rect = $self->_update_rect;
		my $screen_rect = SDL::Rect->new(0, 0, 640, 480);

		$update_rect->clip_ip($screen_rect);

		my @update_rects;
		if ($old_update_rect) {
			$old_update_rect->clip_ip($screen_rect);

			if ($update_rect->colliderect($old_update_rect)) {
				# if the rects collide, update the bigger rect that fits them both
				@update_rects = $update_rect->union($old_update_rect);
			}
			else {
				# if the rects don't collide, update both separately
				@update_rects = ($update_rect, $old_update_rect);
			}
		}
		else {
			@update_rects = $update_rect;
		}

		if (grep Games::Neverhood::SurfaceUtil::rects_equal($_, $screen_rect), @update_rects) {
			$self->invalidate_all();
		}
		else {
			push @_invalidated_rects, @update_rects;
		}

		$self->_set_invalidated(0);
	}

	# draw methods must call these methods to draw
	method draw_surface (Surface $surface, Int $x, Int $y, Rect $clip?)
	{
		my ($w, $h) = $clip ? ($clip->w, $clip->h) : ($surface->w, $surface->h);
		my $update_rect = SDLx::Rect->new($x, $y, $w, $h);

		SDL::Video::blit_surface($surface, $clip, $;->app, $update_rect);
		$self->_update_rect->union_ip($update_rect);
	}
	method draw_rect ($rect, $color) {
		$;->app->draw_rect($rect, $color);
		$self->_update_rect->union_ip($rect);
	}

	method handle_tick {}

	# called when drawables are added/removed from the scene
	method add {
		$self->invalidate();
	}
	method remove {
		$self->_add_update_rect() if $self->_update_rect;
		$self->_set_update_rect(undef);
	}
}
