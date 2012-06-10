use 5.01;
package Games::Neverhood::SmackerPlayer;
use Mouse;

use Games::Neverhood::SmackerDecoder;
use SDL::RWOps;
use SDL::GFX::Rotozoom;
use File::Spec;

# public attributes

has ['x', 'y'] =>
	is => 'rw',
	isa => 'Int',
	default => 0,
;

use constant invalidator_checks => ('x', 'y');

with 'Games::Neverhood::Drawable';

has file =>
	is => 'ro',
	isa => 'Str',
	required => 1,
;
has is_double_size =>
	is => 'ro',
	isa => 'Bool',
	default => 1,
;
has is_loopy =>
	is => 'rw',
	isa => 'Bool',
	default => 1,
;

sub cur_frame   { $_[0]->_decoder->get_cur_frame   }
sub frame_rate  { $_[0]->_decoder->get_frame_rate  }
sub frame_count { $_[0]->_decoder->get_frame_count }

# private attributes

has _time_remainder =>
	is => 'rw',
	isa => 'Num',
	default => 0,
;
has _stream =>
	is => 'rw',
	isa => 'SDL::RWOps',
	init_arg => undef,
;
has _decoder =>
	is => 'rw',
	isa => 'Games::Neverhood::SmackerDecoder',
	init_arg => undef,
;
has _surface =>
	is => 'rw',
	isa => 'SDL::Surface',
	init_arg => undef,
;
has _double_size_surface =>
	is => 'rw',
	isa => 'SDL::Surface',
	init_arg => undef,
;

# methods

sub BUILD {
	my $self = shift;

	$self->_stream(SDL::RWOps->new_file($self->file, 'r')) // $;->error(SDL::get_error());
	$self->_decoder(Games::Neverhood::SmackerDecoder->new($self->_stream));
	$self->_surface($self->_decoder->get_surface);
	$self->first_frame();

	return $self;
}

sub next_frame {
	my $self = shift;

	unless($self->_decoder->next_frame()) {
		if($self->is_loopy) {
			$self->first_frame();
			return -1; # looped
		}
		return 0; # reached end
	}
	$self->_finish_changing_frame();
	return 1; # got to next frame normally
}

sub first_frame {
	my $self = shift;
	$self->_decoder->first_frame();
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

	$time += $self->_time_remainder;
	my $frame_time = 1 / $self->frame_rate;
	my $return = 1; # didn't invalidate
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

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
