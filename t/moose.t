use 5.01;
use strict;
use warnings;
use Test::More;

use MooseX::Declare;
use Method::Signatures::Modifiers;
use Neverhood::Moose;

class Neverhood::HasTest is dirty {
	rw       read_write       => Int;
	ro       read_only        => Int;
	pvt      private          => Int;
	rpvt     read_private     => Int;
	pvt_arg  private_arg      => Int;
	rpvt_arg read_private_arg => Int;
}

my $test = Neverhood::HasTest->new(
	read_write       => 2,
	read_only        => 3,
	private_arg      => 4,
	read_private_arg => 5,
);

is $test->read_write,       2, "read_write arg";
is $test->read_only,        3, "read_only arg";
is $test->_private_arg,     4, "private_arg arg";
is $test->read_private_arg, 5, "read_private_arg arg";

is eval { Neverhood::HasTest->new(private      => 6); 1 }, undef, "private arg illegal";
is eval { Neverhood::HasTest->new(read_private => 7); 1 }, undef, "read_private arg illegal";

$test-> set_read_write      (10);
$test->_set_private         (11);
$test->_set_read_private    (12);
$test->_set_private_arg     (13);
$test->_set_read_private_arg(14);

is $test->read_write,       10, "set and get read_write";
is $test->_private,         11, "set and get private";
is $test->read_private,     12, "set and get read_private";
is $test->_private_arg,     13, "set and get private_arg";
is $test->read_private_arg, 14, "set and get read_private_arg";

is eval { $test->set_read_only(20); 1 }, undef, "set read_only illegal";

is eval { $test->_read_write;       1 }, undef, "illegal get read_write";
is eval { $test->_read_only;        1 }, undef, "illegal get read_only";
is eval { $test->private;           1 }, undef, "illegal get private";
is eval { $test->_read_private;     1 }, undef, "illegal get read_private";
is eval { $test->private_arg;       1 }, undef, "illegal get private_arg";
is eval { $test->_read_private_arg; 1 }, undef, "illegal get read_private_arg";

is eval { $test->_set_read_write     (30); 1 }, undef, "illegal set read_write";
is eval { $test->_set_read_only      (30); 1 }, undef, "illegal set read_only";
is eval { $test->set_private         (30); 1 }, undef, "illegal set private";
is eval { $test->set_read_private    (30); 1 }, undef, "illegal set read_private";
is eval { $test->set_private_arg     (30); 1 }, undef, "illegal set private_arg";
is eval { $test->set_read_private_arg(30); 1 }, undef, "illegal set read_private_arg";

class Neverhood::RequiredTest {
	rw required_rw => Int, required;
}

$test = Neverhood::RequiredTest->new(required_rw => 40);
is $test->required_rw, 40, "required";
is eval { Neverhood::RequiredTest->new; 1 }, undef, "illegal required";

class Neverhood::TriggerTest {
	rw single => Int, trigger;
	rw ['multi1','multi2'] => Int, trigger;
	rw explicit => Int, trigger method (@_) { $self->set_e(63) };
	
	rw ['s', 'm', 'n', 'e'] => Int;
	
	method _single_trigger (@_) { $self->set_s(60) }
	method _multi1_trigger (@_) { $self->set_m(61) }
	method _multi2_trigger (@_) { $self->set_n(62) }
}

$test = Neverhood::TriggerTest->new;

is $test->s, undef, "not triggered single";
is $test->m, undef, "not triggered multi1";
is $test->n, undef, "not triggered multi2";
is $test->e, undef, "not triggered explicit";

$test->set_single(1);
is $test->s, 60, "triggered single";
$test->set_multi1(1);
is $test->m, 61, "triggered multi1";
$test->set_multi2(1);
is $test->n, 62, "triggered multi2";
$test->set_explicit(1);
is $test->e, 63, "triggered explicit";

class Neverhood::BuilderTest {
	rw single => Int, builder;
	rw ['multi1','multi2'] => Int, builder;
	
	method _single_builder { $self->set_single(70) }
	method _multi1_builder { $self->set_multi1(71) }
	method _multi2_builder { $self->set_multi2(72) }
}

$test = Neverhood::BuilderTest->new;

is $test->single, 70, "built single";
is $test->multi1, 71, "built multi1";
is $test->multi2, 72, "built multi2";

done_testing;
