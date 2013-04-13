use 5.01;
use strict;
use warnings;
use lib "lib";
use Games::Neverhood::Util;

class Foo::Bar {
	method asd (@_) {
		say 'in ';
	}

	before asd (@_) {
		say 'before ';
	}

	after asd (@_) {
		say 'after ';
	}

	around asd ($this: @_) {
		say join " ", @_;
		$this->$orig(@_);
		say join " ", @_;
	}
	say __PACKAGE__->meta->is_immutable // 0;
}
my $self = Foo::Bar->new;
say $self->meta->is_immutable // 0;

$self->asd('AROUND');

while (my ($k,$v) = each %Foo::Bar::) {
	print "$k ";
}
