# Scene - the base class for all scenes
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;

class Games::Neverhood::Scene with Games::Neverhood::Ticker {
	use SDL::Constants ':SDL::Events';

	pvt   order      => 'Games::Neverhood::Order';
	rpvt  background => 'Games::Neverhood::Drawable';
	rpvt  movie      => Maybe('Games::Neverhood::MoviePlayer');
	rpvt  palette    => Maybe(Palette);
	rpvt  music      => Maybe('Games::Neverhood::MusicResource');
	rwpvt prev_music => Maybe('Games::Neverhood::MusicResource');

	method BUILD (@_) {
		$self->_set_order(Games::Neverhood::Order->new());
		$self->set_fps(24);
	}
	method setup (SceneName $prev_scene) {}
	
	method handle_time (Num $time) {
		$self->movie->handle_time($time) if $self->movie;
	}
	
	method handle_tick () {
		for my $item (@{$self->_order}) {
			$item->handle_tick()
				unless $item->does('Games::Neverhood::Ticker');
		}
	}
	
	method draw () {
		for my $item (@{$self->_order}) {
			$item->draw();
		}
	}
	
	method add (Maybe[Str]|Maybe[ScalarRef] $name, Games::Neverhood::Drawable $item) {
		if (defined $name) {
			if (ref $name) {
				$$name = $item;
			}
			else {
				$self->$name($item);
				$item->set_name($name) unless defined $item->name;
			}
		}
		$self->_order->add($item);
	}
	
	method add_sprite (Maybe[Str]|Maybe[ScalarRef] $name, Str|Games::Neverhood::Sprite $sprite, @args) {
		unless (ref $sprite) {
			$sprite = Games::Neverhood::Sprite->new(key => $sprite, @args);
		}
		$sprite->set_palette($self->palette) if !$sprite->palette and $self->palette;
		$self->add($name, $sprite);
	}
	
	method add_sequence (Maybe[Str]|Maybe[ScalarRef] $name, Str|Games::Neverhood::Sequence $sequence, @args) {
		unless (ref $sequence) {
			$sequence = Games::Neverhood::Sequence->new(key => $sequence, @args);
		}
		$self->add($name, $sequence);
	}
		
	method set_movie (Str|Games::Neverhood::MoviePlayer $movie, @args) {
		unless (ref $movie) {
			$movie = Games::Neverhood::MoviePlayer->new(key => $movie, @args);
		}
		$self->_order->replace($movie, $self->movie) or $self->_order->add($movie);
		$self->_set_movie($movie);
		$movie->set_name('movie') unless defined $movie->name;
	}
	
	method set_background (Str|Games::Neverhood::Drawable $background, @args) {
		unless (ref $background) {
			$background = Games::Neverhood::Sprite->new(key => $background, @args);
		}
		$self->_order->replace($background, $self->background) or $self->_order->add_at_bottom($background);
		$self->_set_background($background);
		$background->set_name('background') unless defined $background->name;
		$self->set_palette($background) unless $self->palette;
	}
	
	method set_palette (Str|Palette|Games::Neverhood::Sprite $palette) {
		unless (ref $palette) {
			$palette = $;->resource_man->get_palette($palette);
		}
		elsif ($palette->isa('Games::Neverhood::Sprite')) {
			$palette = $palette->palette;
		}
		$self->_set_palette($palette);
	}
	
	method set_music (Str|Games::Neverhood::MusicResource $music) {
		unless (ref $music) {
			$music = $;->resource_man->get_music($music);
		}
		$self->_set_music($music);
	}
}

package Games::Neverhood::Order;

use warnings;
use strict;
use Method::Signatures;

method new ($class:) {
	bless [], $class;
}

method add (Games::Neverhood::Drawable $item) {
	$self->remove($item);
	push @$self, $item;
}

method add_at_bottom (Games::Neverhood::Drawable $item) {
	$self->remove($item);
	unshift @$self, $item;
}

method add_below (Games::Neverhood::Drawable $item, Games::Neverhood::Drawable $target_item) {
	$self->_add_at($item, $target_item, 0);
}

method add_above (Games::Neverhood::Drawable $item, Games::Neverhood::Drawable $target_item) {
	$self->_add_at($item, $target_item, 1);
}

method remove (Games::Neverhood::Drawable $item) {
	my $item_index = $self->_index_of($item);
	return splice @$self, $item_index, 1 if defined $item_index;
	return;
}

method replace (Games::Neverhood::Drawable $item, Maybe[Games::Neverhood::Drawable] $target_item) {
	my $target_index;
	$target_index = $self->_index_of($target_item) if defined $target_item;
	return splice @$self, $target_index, 1, $item if defined $target_index;
	return;
}

method _index_of (Games::Neverhood::Drawable $item) {
	my $item_index;
	while (my ($i, $value) = each @$self) {
		if ($value == $item) {
			$item_index = $i;
		}
	}
	return $item_index;
}

method _add_at (Games::Neverhood::Drawable $item, Games::Neverhood::Drawable $target_item, Int $offset) {
	$self->remove($item);
	my $target_index = $self->_index_of($target_item);
	Carp::confess("Drawable to move to isn't in scene") unless defined $target_index;
	splice @$self, $target_index + $offset, 0, $item;
}

1;
