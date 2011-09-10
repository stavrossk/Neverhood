use 5.01;
use strict;
use warnings;
package Games::Neverhood::Sprite;

use SDL::Image;
use SDL::Video;
use SDL::Rect;
use SDL::GFX::Rotozoom;
use SDL::Mixer::Channels;
use SDL::Mixer::Samples;

use File::Spec ();
use Carp ();

# Overloadable Methods:

# sub new
	# name
	# frame
	# sequence
	# pos
	# hide
	# mirror

# use constant
	# file
	# sequences
	# dir
	# frames

# sub on_move
# sub on_show
# sub on_space
# sub on_click
# sub on_out
# sub on_left
# sub on_right
# sub on_up
# sub on_down

# Other Methods:

# sub move_klaymen_to
# sub in_rect

# sub this_sequence
# sub this_sequence_surface
# sub this_sequence_frame
# sub this_sequence_frames
# sub this_sequence_pos
# sub this_sequence_offset

sub new {
	my $class = shift;
	my $self = bless {@_}, ref $class || $class;

	$self->file or Carp::confess("Sprite: '", $self->name // __PACKAGE__, "' must specify a file");

	#name
	# frame will get set to the default of 0 when we set the sequence
	if($self->sequence) {
		$self->sequence($self->sequence, $self->frame // 0);
	}

	$self->pos([]) unless defined $self->pos;
	$self->pos->[0] //= 0;
	$self->pos->[1] //= 0;
	#hide
	#mirror

	$self->sprite($sprite) if defined $sprite;
	$self;
}

sub DESTROY {}

###############################################################################
# accessors

sub name {
	$_[0]->{name};
}
sub frame {
	my ($self, $frame) = @_;
	if(@_ > 1) {
		if($frame >= $self->this_sequence_frames) {
			# loop back to frame 0
			$_[0]->{frame} = 0;
		}
		else {
			$_[0]->{frame} = $frame;
		}
		# the sprite is moved here. As long as you call this method every frame, everything will be fine
		$_[0]->on_move;
		return $_[0];
	}
	$_[0]->{frame};
}
sub sequence {
	if(@_ > 1) {
		$_[0]->{sequence} = $_[1];
		# we set the frame to 0 for safety, we don't trust you to do it yourself
		# save the value in frame and set it after this if you wanna retain it
		$_[0]->frame(0);
		return $_[0];
	}
	$_[0]->{sequence};
}
sub pos {
	if(@_ > 1) { $_[0]->{pos} = $_[1]; return $_[0]; }
	$_[0]->{pos};
}
sub hide {
	if(@_ > 1) { $_[0]->{hide} = $_[1]; return $_[0]; }
	$_[0]->{hide};
}
sub mirror {
	if(@_ > 1) { $_[0]->{mirror} = $_[1]; return $_[0]; }
	$_[0]->{mirror};
}

###############################################################################
# constant/subs

use constant {
	file      => undef,
	sequences => undef,
	dir       => 'i',
	frames    => 0,
}

###############################################################################
# handler subs

sub on_move {}

sub on_show {
	# TODO: rewrite this
	my ($self) = @_;
	return if $self->hide;
	my $surface = $self->this_surface;
	die 'no surface', $self->flip ? '_flip' : '', ' for: ', File::Spec->catfile(@{$self->folder}, $self->name) unless ref $surface;
	my $h = $surface->h / $self->frames;
	SDL::Video::blit_surface(
		$surface,
		SDL::Rect->new(0, $h * $self->this_sequence_frame, $surface->w, $h),
		$Games::Neverhood::App,
		SDL::Rect->new(
			$self->pos->[0] + (
				$self->flip
				? -$surface->w - $self->offset->[0] + 1
				: $self->offset->[0]
			),
			(
				$self->on_ground
				? 480 - $self->pos->[1] + $self->offset->[1] - $h
				: $self->pos->[1] + $self->offset->[1]
			), 0, 0
		)
	);
}

sub on_space {}
sub on_click { 'no' }
sub on_out {}
sub on_left {}
sub on_right {}
sub on_up {}
sub on_down {}

###############################################################################
# other

sub move_klaymen_to {
	# TODO: this needs to be finalised
	my ($sprite, %arg) = @_;
	for(grep defined, @arg{qw/left right/}) {
		if(ref) {
			$_->[0] = [@$_] if !ref $_->[0];
		}
		else {
			$_ = [[$_]];
		}
	}
	$Klaymen->moving_to({
		%arg,
		sprite => $sprite,
	});
	# sprite => $sprite,
	# left => 1 || [1, 2, 3] || [[1, 2, 3], 4],
	# right => 1 || [1, 2, 3] || [[1, 2, 3], 4],
	# do => sub { $_[0]->hide = 1 },
	# set => ['idle', 0, 2, 1],
	$sprite;
}

sub in_rect {
	my ($sprite, @rect) = @_;
	my $click = Games::Neverhood->cursor->clicked;
	return
		$click and $rect[2] and $rect[3]
		and $click->[0] >= $rect[0] and $click->[1] >= $rect[1]
		and $click->[0] < $rect[0] + $rect[2] and $click->[1] < $rect[1] + $rect[3]
	;
}

sub this_sequence {

}
sub this_sequence_surface {

}
sub this_sequence_frame {

}
sub this_sequence_frames {

}
sub this_sequence_pos {

}
sub this_sequence_offset {

}

1;
