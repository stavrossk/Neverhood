# SmackerPlayer - drawable object to play smacker files
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
package Games::Neverhood::SmackerPlayer;
use Games::Neverhood::Moose;
with 'Games::Neverhood::Drawable';

use SDL::RWOps;
use SDL::GFX::Rotozoom;
use File::Spec;

use constant invalidator_checks => ('x', 'y');

# constants returned by next_frame and advance_in_time
use constant {
	PLAYING => 1,
	LOOPED  => -1,
	ENDED   => 0,
};

# public attributes

has ['x', 'y'] => rw Int,
	default => 0,
;

has file => ro Str,
	required => 1,
;
has is_double_size => ro Bool,
	default => 1,
;
has is_loopy => rw Bool,
	default => 1,
;

sub cur_frame   { $_[0]->_resource->get_cur_frame   }
sub frame_rate  { $_[0]->_resource->get_frame_rate  }
sub frame_count { $_[0]->_resource->get_frame_count }

# private attributes

private _time_remainder => Num,
	default => 0,
;
private _stream =>
	isa => 'SDL::RWOps',
;
private _resource =>
	isa => 'Games::Neverhood::SmackerResource',
;
private _surface =>
	isa => 'SDL::Surface',
;
private _double_size_surface =>
	isa => 'SDL::Surface',
;

# methods

sub BUILD {
	my $self = shift;

	$self->_stream(SDL::RWOps->new_file($self->file, 'r')) // error(SDL::get_error());
	$self->_resource(Games::Neverhood::SmackerResource->new($self->_stream));
	$self->_surface($self->_resource->get_surface);
	$self->_double_size_surface(SDL::GFX::Rotozoom::surface($self->_surface, 0, 2, SMOOTHING_OFF));

	return $self;
}

sub next_frame {
	my $self = shift;

	unless($self->_resource->next_frame()) {
		if($self->is_loopy) {
			$self->first_frame();
			return LOOPED;
		}
		return ENDED;
	}
	$self->_finish_changing_frame();
	return PLAYING;
}

sub first_frame {
	my $self = shift;
	$self->_resource->first_frame();
	$self->_finish_changing_frame();
}

sub _finish_changing_frame {
	my $self = shift;

	if($self->is_double_size) {
		$self->_double_size_surface(SDL::GFX::Rotozoom::surface($self->_surface, 0, 2, SMOOTHING_OFF));
		# remove the color key from it now because rotozoom makes 0,0,0 transparent for some reason
		SDL::Video::set_color_key($self->_double_size_surface, 0, 0);
	}
	$self->invalidate();
}

sub advance_in_time {
	my ($self, $time) = @_;

	my $return = PLAYING; # didn't invalidate
	
	# go to the first frame on the first advance_in_time
	if($self->cur_frame == -1) {
		$return = $self->next_frame();
	}

	$time += $self->_time_remainder;
	my $frame_time = 1 / $self->frame_rate;
	if($time >= $frame_time) {
		$return = $self->next_frame();
		$time -= $frame_time;
	}
	$self->_time_remainder($time);
	return $return;
}

sub surface {
	my $self = shift;
	return $self->is_double_size ? $self->_double_size_surface : $self->_surface;
}

no Games::Neverhood::Moose;
__PACKAGE__->meta->make_immutable;
1;
