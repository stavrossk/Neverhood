use 5.01;
package Games::Neverhood::Drawable;
use Mouse::Role;

# role that standardises drawing
# also handles "invalidating" of rects on the screen to call $app->update() minimally

use SDL::Rect;
use SDL::Video;

our $Is_All_Invalidated;
our @Invalidated_Rects;

# surface needs to return an SDL::Surface
# invalidator_checks needs to return a list of method names to check for changes
requires 'surface', 'invalidator_checks', 'x', 'y';

sub w { $_[0]->surface->w }
sub h { $_[0]->surface->h }

has is_invalidated =>
	is => 'ro',
	isa => 'Bool',
	writer => '_set_is_invalidated',
	init_arg => undef,
;

has _checked =>
	is => 'rw',
	isa => 'HashRef',
	init_arg => undef,
;

has _is_checked =>
	is => 'rw',
	isa => 'Bool',
	init_arg => undef,
;

after BUILD => sub {
	my $self = shift;
	$self->_checked({});
	$self->_update_checking();
	$self->invalidate();
};

# done manually by anything that wants to invalidate the entire screen
sub invalidate_all {
	my $self = shift;
	$Is_All_Invalidated = 1;
	$self->invalidate() if ref $self;
	undef @Invalidated_Rects;
}

# done manually by a surface that wants to be invalidated
sub invalidate {
	my $self = shift;
	return if $self->_is_checked;

	unless($Is_All_Invalidated) {
		my $checked = $self->_checked;
		my ($x, $y, $w, $h) = ($self->x, $self->y, $self->w, $self->h);
		$x = $checked->{x} if exists $checked->{x} and $checked->{x} < $x;
		$y = $checked->{y} if exists $checked->{y} and $checked->{y} < $y;
		$w = $checked->{w} if exists $checked->{w} and $checked->{w} > $w;
		$h = $checked->{h} if exists $checked->{h} and $checked->{h} > $h;

		push @Invalidated_Rects, SDL::Rect->new($x, $y, $w, $h);
	}

	$self->_update_checking();
	$self->_set_is_invalidated(1);
}

# done automatically to invalidate the surface if anything we're checking has changed
sub maybe_invalidate {
	my $self = shift;
	return if $self->_is_checked;

	return $self->invalidate() if $Is_All_Invalidated;

	my $invalidate;
	my $checked = $self->_checked;
	while(my ($k, $v) = each %$checked) {
		unless($v ~~ $self->$k) {
			$invalidate = 1;
			last;
		}
	}

	return $self->invalidate() if $invalidate;
	$self->_update_checking();
}

sub _update_checking {
	my $self = shift;
	return if $self->_is_checked;

	my $checked = $self->_checked;
	for($self->invalidator_checks) {
		$checked->{$_} = $self->$_;
	}

	$self->_is_checked(1);
}

# update rects on the app
sub update_screen {
	if($Is_All_Invalidated) {
		SDL::Video::update_rect($;->app, 0, 0, 0, 0);
	}
	elsif(@Invalidated_Rects) {
		SDL::Video::update_rects($;->app, @Invalidated_Rects);
	}

	undef $Is_All_Invalidated;
	undef @Invalidated_Rects;
}

sub draw {
	my $self = shift;
	SDL::Video::blit_surface($self->surface, undef, $;->app, SDL::Rect->new($self->x, $self->y, 0, 0));
	$self->_is_checked(0);
	$self->_set_is_invalidated(0);
}


no Mouse::Role;
1;
