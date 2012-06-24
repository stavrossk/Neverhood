# Sprite - drawable single image sprites
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
package Games::Neverhood::Sprite;
use Games::Neverhood::Moose;

use SDL::RWOps;

use constant invalidator_checks => ( 'is_mirrored', 'x', 'y' );

with 'Games::Neverhood::Drawable';

# public attributes

has file => ro Str,
	required => 1,
;

has is_mirrored => rw Bool;

# private attributes

private _surface =>
	isa => 'SDL::Surface',
;
private _mirrored_surface =>
	isa => 'SDL::Surface',
;

private _resource =>
	isa => 'Games::Neverhood::SpriteResource',
;

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

no Games::Neverhood::Moose;
__PACKAGE__->meta->make_immutable;
1;
