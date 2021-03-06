use 5.01;
use strict;
use warnings;
package Games::Neverhood::Sprite::Klaymen;

use parent 'Games::Neverhood::Sprite';

use constant {
	name => 'klaymen',
	dir => 's',
	alpha => 0,
	sequences => {
		snore => {
			file => 198,
			frames => [0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,5,6,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23,24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31,32,32,33,33,34,34,34],
		},
		wake => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,18,18,18,19,19,19,19,20,20,20,21,21,21,21,21,21,21,21,21,21,22,22,23,23,24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31,32,32,33,33,34,34,35,35,36,36,36,36,36,37,37,37,37,37,37,38,38,38,38,38,38,39,39,39,40,40,40,40,39,39,39,36,36,36,36,37,37,37,37,38,38,38,38,39,39,39,40,40,40,40,41,41,42,42,43,43,44,44,45,45,46,46,47,47,48,48,49,50,50,51,51,52,52,53,53,54,54,55,55,56,56,57,57,58,58,59,59,60,60,61,61],
			next_sequence => 'idle',
		},
		idle => {
			file => 0,
			frames => [0,0,1,1,2,2],
		},
		idle_blink => {
			file => 0,
			frames => [3,3,4,5,5,6,6],
			next_sequence => 'idle',
		},
		idle_random_0 => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,13,14,15,16,16,17,18,18,19,19,19,19,19,19,20,20,21,21,22,22,23,23,24,24,25,25,26,27,27,28,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,33,34,35,36,37,38,39,40,41,42,43,33,34,35,36,37,38,39,40,41,43,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,54,54,54,54,54,55,55,55,55,55,55,56,56,57,57,58,58,59,59,60,60,61,61,62,62,63,63,64,64,65,65,66,66,67,67,68,68,69,69,70,71,71,72,72,73,73,74,74,75,75,76,76],
			next_sequence => 'idle',
		},
		idle_random_1 => {
			file => 0,
			frames => [0,0,1,1,2,2,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,19,20,20,21,21,22,22,23,23,24,24,25,25,25,26,26,26,27,27,28,28,29,29,30,30,31,31,32,33,33,34,34,35,35,36,36,37,37,38,38,39,39,40,40,41,41,42,42,43,43,44,44,44,45,45,46,46,47,47,48,48,49,49,50,50,51,51,52,52,53,53,54,54,55,55,56,56,57,57,58,58,59,59,60,60,61,61,61,62,62,63,64,64,65,65,66,66,67,67,68,68,69,69,70,70,71,71,72,72,73,73,74,74,75,75,76,76,77,77,78,78,79,79,80,80,81,81,82,82,83,83,84,84,85,85,86,86,87,87,88,88,89,89,90,90,91,91,86,86,92,92,93,94,94,95,95,96,96,97,97,98,98,99,99,100,100,101,101,102,102],
			next_sequence => 'idle',
		},
		idle_random_2 => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,10,10,11,11,12,12,13,14,14,15,15,16,16,17,17,18,18,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23,24,24,25,25,23,23,24,24,25,25,26,26,27,27,28,28,29,29,23,23,24,24,30,31,31,32,32,33,33,34,34,35,35,36,36,34,34,35,35,36,36,34,34,35,35,36,36,34,34,35,35,36,36,37,37,38,38,39,39,40,40,41,41,42,42,43,43,44,44,45,45,46,46,47,47,45,45,46,46,48,48,49,50,50,51,51,45,45,46,46,47,47,45,45,46,46,47,47,45,45,46,46,47,47,48,48,49,49,50,50,51,51,52,52,52,52,52,53,53,54,54,55,55,56,56,57,57,58,58],
			next_sequence => 'idle',
		},
		idle_random_3 => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23,24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31,32,32,33,33,34,34,35,35,36,36,36,36,36,36,36,36,37,37,38,38,39,39,40,40,41,41,42,42,43,43,43,44,44,44,44,45,45,45,45,46,47,48,49,50,46,47,49,50,47,49,50,50,50,50,50,50,50,50,50,50,50,50,50,51,52,53,54,54,50,51,52,53,54,54,50,51,52,53,50,50,50,50,50,50,50,50,50,50,50,50,46,47,48,49,50,46,46,48,48,49,49,50,50,50,50,50,50,50,50,50,50,50,50,51,52,53,54,54,50,51,52,53,54,54,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,56,56,57,57,58,58,59,59,60,60,61,61,62,62,63,63,64,64,65,65,66,66,67,67,68,68,69,69,70,71,71,72,72],
			next_sequence => 'idle',
		},
		idle_random_4 => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,6,7,7,7,8,8,8,9,9,10,10,11,11,12,12,13,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31,32,32,33,33,34,34,35,35,36,36,37,37,38,38,39,39,40,40,41,41,42,42,43,43,44,44,45,45,46,46,47,47,48,48,49,49,50,50,51,51,52,52,53,53,54,55,55,56,56,57,57,58,58,59,59,60,60,61,61,62,62,63,63,64,64,65,65,66,66,67,67,68,68,69,69,70,70,71,71,72,72,73,73,74,74,75,75,76,76,77,77,78,78,79,79,80,80,81,81,82,82,83,83,84,84,85,86,86,87,87,88,88,89,89,90,90,91,91,92,92,93,93,94,94,95,95,96,96,97,97,98,98,99,99,100,100,101,101,102,102,103,103,103,103,104,104,104,104,105,105,105,105,106,106,107,107,108,108,109,109,110,110,111,111,112,112,113,113,114,115,115,116,116,117,117,118,118,119,119,120,120,121,121,122,122,123,123,124,124,125,125,126,126,127,127,128,128,129,129,130,130,131,131,132,132,119,119,120,120,121,121,122,122,123,123,124,124,125,125,126,126,127,127,128,128,129,129,130,130,131,131,132,132,132,132,132,132,132,132,133,133,134,134,135,135,136,136,137,137],
			next_sequence => 'idle',
		},
		think => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,8,8,9,9,10,10,8,8,9,9,10,10,8,8,9,10,10,11,11,12,12,13,13,8,8,9,9,10,10,11,11,12,12,13,13,8,8,9,9,10,10,14,14,15,15,16,16,17,17,18,18,19,19,20,20,21,21],
			next_sequence => 'idle',
		},
		pull_lever => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,16,16,15,15,14,14,13,13,19,19,20,20,21,21,22,22,23,23,24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31],
			next_sequence => 'idle',
		},
		push_button_back => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,9,9,10,10,11,12,13,13,14,14,15,16,16,17,17,18,18,19,20,21,22,23,24,25,26,26,27,28,28,29,30,30,31,31,32,32,32,33,33,33,33,34,34,34,35,35,36,36,37,37,38,38,39,39,40,40,41,41,42,42,43,43,44,44,45,45,46,46,47,47,48,48,49,49,50,51,51,52,53,53],
			next_sequence => 'idle',
		},
		turn_to_back => {
			file => 0,
			frames => [7,7,8,9,9,10,10,11,12,13,13,14,14],
		},
		turn_from_back => {
			file => 0,
			frames => [44,44,45,45,46,46,47,47],
			next_sequence => 'idle',
		},
		walk => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9],
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13],
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7],
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,8,8,9,9,10,10,11,11],
			frames => [12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20,20,11,11,21,21,6,6,22,22,7,7],
		},
		shuffle => {
			file => 0,
			frames => [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7],
			frames => [0,0,1,1,2,2],
		},
		slide => {
			file => 0,
			frames => [ 0,0,1,1,2,2,3,3,4,4,5,5,6,6 ],
			frames => [ 0,0,1,1,2,2,3,3,4,4 ],
		},
	},
};

sub file {
	my ($self) = @_;
	$self->this_sequences->{file};
}
sub pos {
	my ($self) = @_;
	if(@_ > 1) { $self->{pos} = $_[1]; return $self; }
	# we place klaymen's bottom pixel relative to the bottom instead of his top to the top
	my $pos = $self->{pos};
	[$pos->[0], 480 - $pos->[1] - $self->this_surface->h];
}

sub blink_in {
	if(@_ > 1) { $_[0]->{blink_in} = $_[1]; return $_[0]; }
	$_[0]->{blink_in};
}
sub random_in {
	if(@_ > 1) { $_[0]->{random_in} = $_[1]; return $_[0]; }
	$_[0]->{random_in};
}
sub moving_to {
	if(@_ > 1) { $_[0]->{moving_to} = $_[1]; return $_[0]; }
	$_[0]->{moving_to};
}

# sub on_move {
	# my ($self, $step, $app) = @_;
	# return unless $self->klaymen;
	# if($Klaymen->sprite eq 'idle') {
		# if(defined $Klaymen->blink_in) {
			# $Klaymen->blink_in($Klaymen->blink_in - $_[0]);
			# $Klaymen->random_in($Klaymen->random_in - $_[0]);
			# if($Klaymen->blink_in <= 0) {
				# $Klaymen->sequence(1);
				# $Klaymen->blink_in(undef);
			# }
			# if($Klaymen->random_in <= 0) {
				# $Klaymen->sprite('idle_random_' . int rand 5);
				# $Klaymen->random_in(undef);
			# }
		# }
		# $Klaymen->blink_in(int rand(40) + 30) unless defined $Klaymen->blink_in;
		# $Klaymen->random_in(int rand(40) + 600) unless defined $Klaymen->random_in;
	# }
	# else {
		# $Klaymen->blink_in(undef);
		# $Klaymen->random_in(undef);
	# }
	# if(my $move = $Klaymen->moving_to) {
		# my ($to, @type);
		# {
			# no warnings 'uninitialized';
			# my $min = 1e100;
			# for(qw/left right to/) {
				# my $v;
				# if($_ eq 'to') {
					# $v = $move->{to};
				# }
				# else {
					# (undef, $v) = each @{$move->{$_}[0]};
				# }
				# next unless defined $v;
				# my $new = abs($v - $Klaymen->pos->[0]);
				# if($new < $min) {
					# ($min, $to) = ($new, $v);
					# @type = $_;
				# }
				# elsif($new == $min and $to == $v) {
					# push @type, $_;
				# }
				# redo unless $_ eq 'to';
			# }
		# }
		# ;#( $maximum, $minimum )
		# my $adjust = (5,  );
		# my @shuffle = (20, $adjust);
		# my @slide = (100, $shuffle[0]);
		# my @walk_stop = (40, $shuffle[0]);
		# my $further = abs($to - $Klaymen->pos->[0]);
		# my $dir = $to <=> $Klaymen->pos->[0];
		# my $left = $dir - 1;

		# if($further) {
			# if($Klaymen->sprite eq 'idle') {
				# if($further <= $adjust) {
					# $Klaymen->pos->[0] += 2 * $_[0];
				# }
			# }
		# }
		# else {
			# set or do
		# }
		# if($Klaymen->pos->[0] == $to) {
			# if($Klaymen->get('idle')) {
				# if(defined $move->{do}) {
					# $M{scene}->call($move->{do}, $move->{sprite}, $click);
				# }
				# if(defined $move->{set}) {
					# $Klaymen->set(@{$move->{set}});
				# }
				# elsif(!defined $move->{do}) {
					# $Klaymen->set('idle');
				# }
				# delete $M{move_to};
			# }
		# }
		# elsif($Klaymen->flip == ($Klaymen->pos->[0] > $to ? 1 : 0)) {
			# if($Klaymen->get('idle_walk')) {
				# if($further >= $walk_stop[0]) {
					# if($Klaymen->to_frame > 0 and not $Klaymen->to_frame % 2) {
						# $Klaymen->pos->[0] += 10 * $dir;
					# }
					# elsif($Klaymen->to_frame eq 'end') {
						# $Klaymen->pos->[0] += 20 * $dir;
					# }
				# }
				# elsif(1) { }
			# }
			# elsif($Klaymen->get('idle_walk_start')) {

			# }
			# elsif($Klaymen->get('idle_walk_end')) {

			# }
			# elsif($Klaymen->get('idle_shuffle')) {

			# }
			# elsif($Klaymen->get('idle_shuffle_end')) {

			# }
			# elsif($Klaymen->get('idle_slide')) {

			# }
			# elsif($Klaymen->get('idle_slide_end')) {

			# }
		# }
		# elsif($further <= $adjust) {
			# my $speed = 5;
			# $Klaymen->flip($left);
			# $Klaymen->pos->[0] += $speed * $dir * $_[0];
			# $Klaymen->pos->[0] = $to if $further <= $speed * $_[0];
		# }
		# if($to > $Klaymen->pos->[0]) {
			# $Klaymen->flip(0);
		# }
		# elsif($to < $Klaymen->pos->[0]) {
			# $Klaymen->flip(1);
		# }
	# }
# }

# sub move_bounds {
	# if($self->sprites->{klaymen} and !$self->klaymen->no_interrupt) {
		# my $bound;
		# if(
			# $bound = $self->move_klaymen_bounds and
			# $bound->[0] <= $click->[0] and $bound->[1] <= $click->[1] and
			# $bound->[2] >= $click->[0] and $bound->[3] >= $click->[1] and

			# !$self->klaymen->sprite eq 'idle' ||
			# ($click->[0] < $self->klaymen->pos->[0] - 38 || $click->[0] > $self->klaymen->pos->[0] + 38)
		# ) {
			# $self->klaymen->move_to(to => $click->[0]);
		# }
		# $self->cursor->clicked(undef);
		# return;
	# }
# }

# sub move_to {
	# TODO: this needs to be finalised
	# my ($sprite, %arg) = @_;
	# for(grep defined, @arg{qw/left right/}) {
		# if(ref) {
			# $_->[0] = [@$_] if !ref $_->[0];
		# }
		# else {
			# $_ = [[$_]];
		# }
	# }
	# $_->klaymen->moving_to({
		# %arg,
		# sprite => $sprite,
	# });
	# sprite => $sprite,
	# left => 1 || [1, 2, 3] || [[1, 2, 3], 4],
	# right => 1 || [1, 2, 3] || [[1, 2, 3], 4],
	# do => sub { $_[0]->hide = 1 },
	# set => ['idle', 0, 2, 1],
	# $sprite;
# }

1;
