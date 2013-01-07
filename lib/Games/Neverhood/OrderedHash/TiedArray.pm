# TiedArray::TiedArray - tied array interface for OrderedHash
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
use warnings;
use strict;

package Games::Neverhood::OrderedHash::TiedArray;

use Games::Neverhood::OrderedHash qw/ORDER HASH/;
use Method::Signatures;

*TIEARRAY = \&Games::Neverhood::OrderedHash::TiedHash::TIEHASH;

method FETCH ($index) {
		return $self->[HASH]{$self->[ORDER][$index]}
	if $index < @{$self->[ORDER]};
	return;
}
method STORE ($index, $value) {
		return $self->[HASH]{$self->[ORDER][$index]} = $value
	if $index < @{$self->[ORDER]};
	Carp::confess("Modification of ordered hash index $index with no corresponding key");
}
method FETCHSIZE {
	scalar @{$self->[ORDER]};
}
sub STORESIZE {}
sub EXTEND {}
method EXISTS ($index) {
		return exists $self->[HASH]{$self->[ORDER][$index]}
	if $index < @{$self->[ORDER]};
	return;
}
method DELETE ($index) {
		return delete $self->[HASH]{$self->[ORDER][$index]}
	if $index < @{$self->[ORDER]};
	return;
}
*CLEAR = \&Games::Neverhood::OrderedHash::TiedHash::CLEAR;
method POP {
		return delete $self->[HASH]{pop @{$self->[ORDER]}}
	if @{$self->[ORDER]};
	return;
}
method SHIFT {
		return delete $self->[HASH]{shift @{$self->[ORDER]}}
	if @{$self->[ORDER]};
	return;
}
method SPLICE (@_) {
	@_ > 2 and Carp::confess("Supplying a replacement list in splice is illegal");

	my @deleted;
	for (splice @{$self->[ORDER]}, @_) {
		push @deleted, delete $self->[HASH]{$_};
	}
	return wantarray ? @deleted : pop @deleted;
}
sub PUSH {
	Carp::confess("Pushing or unshifting an ordered hash is illegal");
}
*UNSHIFT = \&PUSH;
*UNTIE = \&Games::Neverhood::OrderedHash::TiedHash::UNTIE;

1;
