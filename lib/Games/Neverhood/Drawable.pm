# Drawable - role that standardises drawing
# Also handles "invalidating" of rects on the screen to call $app->update() minimally.
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use MooseX::Declare;

role Games::Neverhood::Drawable {
	# draw_surfaces needs to draw the surfaces and update w and h
	# invalidator_checks needs to return a list of method names to check for changes
	requires 'draw_surfaces', 'invalidator_checks';

	my $_is_all_invalidated; # => private Bool;
	my @_invalidated_rects;  # => private ArrayRef(Surface);

	use constant is_visible => 1;

	has ['x', 'y'] => rw Int, default => 0;
	has ['w', 'h'] => private_set Int;

	has is_invalidated => private_set Bool;
	has _checked       => private HashRef;
	has _is_checked    => private Bool;

	method rect (Rect $rect) {
		if($rect) {
			$self->x($rect->x);
			$self->y($rect->y);
			$self->w($rect->w);
			$self->h($rect->h);
			return $self;
		}
		return SDLx::Rect->new($self->x, $self->y, $self->w, $self->h);
	}

	# methods

	after BUILD {
		$self->invalidate();
	}

	# done manually by anything that wants to invalidate the entire screen
	method invalidate_all (Object|ClassName $self:) {
		$_is_all_invalidated = 1;
		$self->invalidate() if ref $self;
		@_invalidated_rects = ();
	}

	# done manually by a surface that wants to be invalidated
	method invalidate () {
		return if $self->_is_checked;

		unless($_is_all_invalidated) {
			my $screen_rect = SDL::Rect->new(0, 0, $;->app->w, $;->app->h);

			my ($x, $y, $w, $h) = ($self->x, $self->y, $self->w, $self->h);
			my $rect = SDLx::Rect->new($x, $y, $w, $h);
			$rect->clip_ip($screen_rect);

			my $checked = $self->_checked;
			my $checked_rect = SDLx::Rect->new;

			my $checked_w = exists $checked->{w} ? $checked->{w} : $w;
			my $checked_h = exists $checked->{h} ? $checked->{h} : $h;
			$checked_rect->size($checked_w, $checked_h);

			if(exists $checked->{x} or exists $checked->{y}) {
				my $checked_x = exists $checked->{x} ? $checked->{x} : $x;
				my $checked_y = exists $checked->{y} ? $checked->{y} : $y;
				$checked_rect->topleft($checked_y, $checked_x);
				$checked_rect->clip_ip($screen_rect);

				if($rect->colliderect($rect)) {
					# if the rects collide, update the bigger rect that fits them both
					push @_invalidated_rects, $rect->union($checked_rect);
				}
				else {
					# if the rects don't collide, update both separately
					push @_invalidated_rects, $rect, $checked_rect;
				}
			}
			else {
				$checked_rect->topleft($y, $x);
				$checked_rect->clip_ip($screen_rect);
				push @_invalidated_rects, $rect->union($checked_rect);
			}
		}

		$self->_update_checking();
		$self->is_invalidated(1);
	}

	# done automatically to invalidate the surface if anything we're checking has changed
	method maybe_invalidate () {
		return if $self->_is_checked;

		return $self->invalidate() if $_is_all_invalidated;

		my $checked = $self->_checked;
		while(my ($k, $v) = each %$checked) {
			if($v !~~ $self->$k) {
				return $self->invalidate();
			}
		}

		$self->_update_checking();
	}

	method _update_checking () {
		error("Wanted to update checking twice") if $self->_is_checked;

		my $checked = $self->_checked;
		for($self->invalidator_checks) {
			$checked->{$_} = $self->$_;
		}

		$self->_is_checked(1);
	}

	# update rects on the app
	method update_screen (Object|ClassName $self:) {
		if($_is_all_invalidated) {
			SDL::Video::update_rect($;->app, 0, 0, 0, 0);
		}
		elsif(@_invalidated_rects) {
			SDL::Video::update_rects($;->app, @_invalidated_rects);
		}

		$_is_all_invalidated = 0;
		@_invalidated_rects = ();
	}

	method draw () {
		$self->draw_surfaces() if $self->is_visible;
		$self->_is_checked(0);
		$self->is_invalidated(0);
	}
	
	method draw_surface (Surface $surface) {
		$self->w($surface->w);
		$self->h($surface->h);
		SDL::Video::blit_surface($surface, undef, $;->app, SDL::Rect->new($self->x, $self->y, 0, 0));
	}
}

1;
