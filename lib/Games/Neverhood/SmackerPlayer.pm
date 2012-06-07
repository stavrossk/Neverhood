use 5.01;
package Games::Neverhood::SmackerPlayer;
use Mouse;

use Games::Neverhood::SmackerVideo;

use File::Spec;

has file =>
	is => 'ro',
	isa => 'Str',
	required => 1,
;

has pos =>
	is => 'rw',
	isa => 'ArrayRef[Int]',
	default => sub { [0, 0] },
;

has video =>
	is => 'ro',
	isa => 'Games::Neverhood::SmackerVideo',
	writer => '_set_video',
	init_arg => undef,
;

has surface =>
	is => 'ro',
	isa => 'SDL::Surface',
	writer => '_set_surface',
	init_arg => undef,
;

sub BUILD {
	my $self = shift;
	
	my $filename = $;->share_dir($self->file . '.0A');
	
	$self->_set_video(Games::Neverhood::SmackerVideo->new($filename));
	$self->_set_surface($self->video->get_surface);
	
	return $self;
}

sub draw {
	my $self = shift;
	
	SDL::Video::blit_surface($self->surface, SDL::Rect->new(0, 0, 400, 300), $;->app, SDL::Rect->new(@{$self->pos}, 0, 0));
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
