use 5.01;
use strict;
use warnings;
use lib "lib";
use Neverhood::Base;

role Goo::Par {
	requires 'asd';
	before asd (@_) {
		say 'ROEL BEFOER';
	}
}

class Foo::Bar {
	our @_WITH = 'Goo::Par';
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

say join " ", keys %Foo::Bar::;
