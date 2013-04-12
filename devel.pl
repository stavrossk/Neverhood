use 5.01;
use strict;
use warnings;
use lib "lib";
use Method::Signatures;
use Mouse;
use Games::Neverhood::Util::Declare;

class Foo {
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
	say Foo->meta->is_immutable // 0;
}
my $self = Foo->new;
say $self->meta->is_immutable // 0;


$self->asd('AROUND');

