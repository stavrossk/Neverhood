# Drawable - role that standardises drawing
# Also handles "invalidating" of rects on the screen to call $app->update() minimally.
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
package Games::Neverhood::Drawable;
use Games::Neverhood::Moose::Role;

our $Is_All_Invalidated;
our @Invalidated_Rects;

# surface needs to return an SDL::Surface
# invalidator_checks needs to return a list of method names to check for changes
# requires 'surface', 'invalidator_checks', 'x', 'y';

use constant is_visible => 1;

sub w { $_[0]->surface->w }
sub h { $_[0]->surface->h }

private_set is_invalidated => Bool;

private _checked => HashRef;

private _is_checked => Bool;

sub rect {
	my $self = shift;
	if(@_) {
		my $rect = shift;
		$self->x($rect->x);
		$self->y($rect->y);
		$self->w($rect->w);
		$self->h($rect->h);
		return $self;
	}
	return SDLx::Rect->new($self->x, $self->y, $self->w, $self->h);
}

# methods

after BUILD => sub {
	my $self = shift;
	$self->_checked({});
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
				push @Invalidated_Rects, $rect->union($checked_rect);
			}
			else {
				# if the rects don't collide, update both separately
				push @Invalidated_Rects, $rect, $checked_rect;
			}
		}
		else {
			$checked_rect->topleft($y, $x);
			$checked_rect->clip_ip($screen_rect);
			push @Invalidated_Rects, $rect->union($checked_rect);
		}
	}

	$self->_update_checking();
	$self->_set_is_invalidated(1);
}

# done automatically to invalidate the surface if anything we're checking has changed
sub maybe_invalidate {
	my $self = shift;
	return if $self->_is_checked;

	return $self->invalidate() if $Is_All_Invalidated;

	my $checked = $self->_checked;
	while(my ($k, $v) = each %$checked) {
		if($v !~~ $self->$k) {
			return $self->invalidate();
		}
	}

	$self->_update_checking();
}

sub _update_checking {
	my $self = shift;
	error("Wanted to update checking twice") if $self->_is_checked;

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
	$self->draw_surface() if $self->is_visible;
	$self->_is_checked(0);
	$self->_set_is_invalidated(0);
}
sub draw_surface {
	my $self = shift;
	SDL::Video::blit_surface($self->surface, undef, $;->app, SDL::Rect->new($self->x, $self->y, 0, 0));
}

no Games::Neverhood::Moose::Role;
1;
