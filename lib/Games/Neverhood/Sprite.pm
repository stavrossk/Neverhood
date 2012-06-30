# Sprite - drawable single image sprites
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
use MooseX::Declare;

class Games::Neverhood::Sprite with Games::Neverhood::Drawable {
	use constant invalidator_checks => ( 'is_mirrored', 'x', 'y' );

	# public attributes

	has file        => ro Str, required => 1;
	has is_mirrored => rw Bool;

	# private attributes

	has _surface          => private 'SDL::Surface';
	has _mirrored_surface => private 'SDL::Surface';
	has _resource         => private 'Games::Neverhood::SpriteResource';

	# methods

	sub BUILD {
		my $self = shift;

		my $stream = SDL::RWOps->new_file($self->file, 'r') // error(SDL::get_error());
		$self->_resource(Games::Neverhood::SpriteResource->new($stream));
		$self->_surface($self->_resource->get_surface);

		return $self;
	}

	sub x { $_[0]->_resource->get_x }
	sub y { $_[0]->_resource->get_y }

	sub surface {
		my $self = shift;
		# TODO: mirrored_surface

		$self->_surface;
	}
}

1;
