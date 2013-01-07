# OrderedHash::TiedHash - tied hash interface for OrderedHash
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
use warnings;
use strict;

package Games::Neverhood::OrderedHash::TiedHash;

use Games::Neverhood::OrderedHash qw/ORDER HASH/;
use Method::Signatures;

method TIEHASH ($class: $tie) {
	bless $tie, $class;
}

method FETCH ($key) {
	$self->[HASH]{$key};
}
method STORE ($key, $value) {
	# if key is not in Order, push it in
	unless (
		exists $self->[HASH]{$key}
		or exists { map {$_ => undef} @{$self->[ORDER]} }->{$key}
	) {
		push @{$self->[ORDER]}, $key
	}
	$self->[HASH]{$key} = $value;
}
method DELETE ($key) {
	delete $self->[HASH]{$key};
}
method CLEAR {
	%{$self->[HASH]} = ();
}
method EXISTS ($key) {
	exists $self->[HASH]{$key};
}
method FIRSTKEY {
	keys %{$self->[HASH]};
	$self->NEXTKEY;
}
method NEXTKEY (@_) {
	my $key;
	while ((undef, $key) = each @{$self->[ORDER]}) {
		exists $self->[HASH]{$key} and return $key
	}
	return;
}
method SCALAR {
	scalar %{$self->[HASH]};
}
sub UNTIE {
	Carp::confess('Can not untie ordered hash ties');
}

1;
