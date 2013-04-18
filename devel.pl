use 5.01;
use strict;
use warnings;
use lib "lib";
use Neverhood::Base;
use Neverhood;

role Goo::Par {
	requires qw/asd foo bar/;

	rw oh_no => 'Str';

	before asd (@_) {
		say 'ROEL BEFOER';
	}
}

class Foo::Bar {
	with 'Goo::Par';

	rw foo  => Str, default => 'YUP';
	ro bar  => Int, build { 1333333337 };
	pvt baz => Str;
	pvt moo => Str, trigger, build;
	rw sprite => Role::Draw;

	method asd (@_) {
		say sprintf "foo => %s, bar => %s", $self->foo, $self->bar;
		say $self->oh_no if defined $self->oh_no;
		$self->_set_baz('scary');
		say $self->_baz;
		$self->_set_moo("fart");
		$self->_set_moo("That's Yucky");
		$self->set_sprite(Moo::Mar->new);
		$self->do_something($self->sprite);
	}

	before asd {
		say 'before ';
	}

	after asd {
		say 'after ';
		
		$self->sprite->check_stuff;
	}

	around asd ($this: @_) {
		say join " ", @_;
		$this->$orig(@_);
		say join " ", @_;
	}
	
	trigger moo {
		say sprintf "%s %s", $new, $old // '';
	}
	
	build moo {
		say "Woah. I'm about to build moo";
		'building is epic';
	}
	
	method do_something (Role::Draw $sprite) {
		$sprite->invalidate;
		say 'this better say 1 -----> ' . $sprite->invalidated;
	}
	
	say __PACKAGE__->meta->is_immutable // 0;
}

class Moo::Mar {
	with Role::Draw;
	
	rw  bool    => Maybe[Bool], check;
	rw_ int     => Maybe[Int], check;
	pvt str     => Maybe[Str], check;
	rw  surface => Maybe[Surface], check, trigger;
	rw  rect    => Maybe[Rect], check, trigger { 'do nothing, just look pretty' };
	
	trigger surface { 'nothing to see here' }
	
	method draw {}
	
	method check_stuff {
		my $surface = SDLx::Surface->new(w=>1,h=>2);
	
		$self->set_invalidated(0);
		
		say 'starting at 0 ----> ' . $self->invalidated;
		
		say 'bunch of 1s ahead, plz';
		
		$self->set_bool(1);
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_int(5);
		say $self->invalidated; $self->set_invalidated(0);
		$self->_set_str('asd');
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_surface($surface);
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_rect(SDLx::Rect->new(1,4,6,8));
		say $self->invalidated; $self->set_invalidated(0);
		
		say 'better get a bunch of 0s now.';
		
		$self->set_bool(1);
		say $self->invalidated;
		$self->set_int(5);
		say $self->invalidated;
		$self->_set_str('asd');
		say $self->invalidated;
		$self->set_surface($surface);
		say $self->invalidated;
		$self->set_rect(SDLx::Rect->new(1,4,6,8));
		say $self->invalidated;
		
		say 'better get a bunch of 1s now.';
		
		$self->set_bool(undef);
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_int(-5);
		say $self->invalidated; $self->set_invalidated(0);
		$self->_set_str('ASD');
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_surface(SDLx::Surface->new(w=>1,h=>2));
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_rect(SDLx::Rect->new(1,0,0,0));
		say $self->invalidated; $self->set_invalidated(0);
		
		$self->set_bool('1');
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_int(undef);
		say $self->invalidated; $self->set_invalidated(0);
		$self->_set_str(undef);
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_surface(undef);
		say $self->invalidated; $self->set_invalidated(0);
		$self->set_rect(undef);
		say $self->invalidated; $self->set_invalidated(0);
		
		say 'and now finally a bunch more 0s';
		
		$self->set_bool(1);
		say $self->invalidated;
		$self->set_int(undef);
		say $self->invalidated;
		$self->_set_str(undef);
		say $self->invalidated;
		$self->set_surface(undef);
		say $self->invalidated;
		$self->set_rect(SDLx::Rect->new);
		say $self->invalidated;
	}
}

my $self = Foo::Bar->new(foo => 'NOPE', oh_no => "It's a disaster!");
say $self->meta->is_immutable // 0;

$self->asd('AROUND');

say join " ", keys %Foo::Bar::;
