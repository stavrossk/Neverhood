=head1 NAME

Neverhood::Scene - the base class for all scenes

=cut

class Neverhood::Scene {
	use SDL::Constants ':SDL::Events';

	pvt order      => 'Neverhood::Order', handles => [qw( add add_above add_below replace remove )];
	rw_ background => 'Neverhood::Draw';
	rw_ movie      => Maybe['Neverhood::MoviePlayer'];
	rw_ palette    => Maybe[Palette];
	rw_ music      => Maybe['Neverhood::MusicResource'];
	rw_ prev_music => Maybe['Neverhood::MusicResource'];

	method BUILD (@_) {
		$self->_set_order(Neverhood::Order->new());
		$self->set_fps(24);
	}
	method setup (SceneName $prev_scene) {}

	method handle_time (Num $time) {
		$self->movie->handle_time($time) if $self->movie;
	}

	method handle_tick () {
		for my $item (@{$self->_order}) {
			$item->handle_tick()
				if !$item->does('Neverhood::Tick');
		}
	}

	method draw () {
		for my $item (@{$self->_order}) {
			$item->draw();
		}
	}

	method _name_item (Undef|Str|ScalarRef $name, Neverhood::Draw $item) {
		return if !defined $name;
		if (ref $name) {
			$$name = $item;
		}
		else {
			my $setter = "set_$name";
			$self->$setter($item);
			$item->set_name($name) if !length $item->name;
		}
	}

	method add_named (Neverhood::Draw $item, Undef|Str|ScalarRef|ArrayRef $name?) {
		$self->_name_item($name, $item);
		$self->_order->add($item);
	}

	method add_sprite (ResourceKey $sprite, Undef|Str|ScalarRef|ArrayRef $name?, @args) {
		$sprite = Neverhood::Sprite->new(key => $sprite, @args);
		$sprite->set_palette($self->palette) if !$sprite->palette and $self->palette;
		$self->add_named($sprite, $name);
	}

	method add_sequence (ResourceKey $sequence, Undef|Str|ScalarRef $name, @args) {
		$sequence = Neverhood::Sequence->new(key => $sequence, @args);
		$self->add_named($sequence, $name);
	}

	method add_above_background (Neverhood::Draw $item) {
		$self->_order->add_above($item, $self->background);
	}

	method set_movie (ResourceKey|Neverhood::MoviePlayer $movie, @args) {
		if ($movie->isa(ResourceKey)) {
			$movie = Neverhood::MoviePlayer->new(key => $movie, @args);
		}
		if ($self->movie) {
			$self->movie->stop;
			$self->_order->replace($movie, $self->movie);
		}
		else {
			$self->_order->add($movie);
		}
		$self->_set_movie($movie);
		$movie->set_name('movie') if !length $movie->name;
	}

	method set_background (ResourceKey|Neverhood::Draw $background, @args) {
		if ($background->isa(ResourceKey)) {
			$background = Neverhood::Sprite->new(key => $background, @args);
		}
		$self->_order->replace($background, $self->background) or $self->_order->add_at_bottom($background);
		$self->_set_background($background);
		$background->set_name('background') if !length $background->name;
		$self->set_palette($background) if !$self->palette;
	}

	method get_palette (ResourceKey|Palette|Surface|Neverhood::Sprite|Neverhood::Sequence|Neverhood::Scene $palette) {
		return undef if !defined $palette;
		return $;->resource_man->get_palette($palette) if $palette->isa(ResourceKey);
		return $palette if $palette->isa(Palette);
		return $palette->format->palette if $palette->isa(Surface);
		return $palette->palette;
	}

	method set_palette (Undef|ResourceKey|Object $palette) {
		$self->_set_palette($self->get_palette($palette));
	}

	method set_music (ResourceKey|Neverhood::MusicResource $music) {
		if ($music->isa(ResourceKey)) {
			$music = $;->resource_man->get_music($music);
		}
		$self->_set_music($music);
	}
}

package Neverhood::Order;

use Neverhood::Base;

method new ($class:) {
	bless [], $class;
}

method add (Neverhood::Draw $item) {
	$self->remove($item);
	push @$self, $item;
	$item->add();
	return $item;
}

method add_at_bottom (Neverhood::Draw $item) {
	$self->remove($item);
	unshift @$self, $item;
	$item->add();
	return $item;
}

method add_below (Neverhood::Draw $item, Neverhood::Draw $target_item) {
	$self->_add_at($item, $target_item, 0);
}

method add_above (Neverhood::Draw $item, Neverhood::Draw $target_item) {
	$self->_add_at($item, $target_item, 1);
}

method remove (Neverhood::Draw $item) {
	my $item_index = $self->_index_of($item);
	return splice @$self, $item_index, 1 if defined $item_index;
	$item->remove();
	return;
}

method replace (Neverhood::Draw $item, Maybe[Neverhood::Draw] $target_item) {
	$self->remove($item);
	my $target_index;
	$target_index = $self->_index_of($target_item) if defined $target_item;
	return splice @$self, $target_index, 1, $item if defined $target_index;
	$item->add();
	return;
}

method _index_of (Neverhood::Draw $item) {
	my $item_index;
	while (my ($i, $value) = each @$self) {
		if ($value == $item) {
			$item_index = $i;
		}
	}
	return $item_index;
}

method _add_at (Neverhood::Draw $item, Neverhood::Draw $target_item, Int $offset) {
	$self->remove($item);
	my $target_index = $self->_index_of($target_item);
	Carp::confess("Drawable to move to isn't in scene") if !defined $target_index;
	splice @$self, $target_index + $offset, 0, $item;
	$item->add();
	return $item;
}

no Neverhood::Base;
1;
