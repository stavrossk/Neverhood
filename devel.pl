use 5.01;
use strict;
use warnings;
use lib "lib";
use Neverhood::Base;

role Goo::Par {
	requires qw/asd foo bar/;

	rw oh_no => 'Str';

	before asd (@_) {
		say 'ROEL BEFOER';
	}
}

class Foo::Bar {
	with 'Goo::Par';

	rw foo => 'Str', default => 'YUP';
	ro bar => 'Int', default => 2;
	pvt baz => 'Str';
	pvt moo => 'Str', changing, build;

	method asd (@_) {
		say sprintf "foo => %s, bar => %s", $self->foo, $self->bar;
		say $self->oh_no if defined $self->oh_no;
		$self->_set_baz('scary');
		say $self->_baz;
		$self->_set_moo("fart");
		$self->_set_moo("That's Yucky");
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
	
	changing moo {
		say sprintf "%s %s", $new, $old // '';
	}
	
	build moo {
		say "Woah. I'm about to build moo";
		'epic building is epic';
	}
	
	say __PACKAGE__->meta->is_immutable // 0;
}

my $self = Foo::Bar->new(foo => 'NOPE', bar => 42, oh_no => "It's a disaster!");
say $self->meta->is_immutable // 0;

$self->asd('AROUND');

say join " ", keys %Foo::Bar::;
