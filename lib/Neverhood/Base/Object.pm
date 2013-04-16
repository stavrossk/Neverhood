=head1 NAME

Neverhood::Base::Object - Some "has" sugar and whateverelse

=cut

use 5.01;
use strict;
use warnings;

package Neverhood::Base::Object;
use Mouse ();
use Mouse::Role ();
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [
		qw( ro ro_ rw rw_ ),
		qw( check trigger ),
		# qw( required ),
		# qw( builder )
		# qw( weak_ref lazy ),
		qw( with ),
	],
	also => [ 'Neverhood::Base::Util' ],
);

# attribute declaration customised
sub has {
	my $meta = caller->meta;
	my $name = shift;

	$meta->throw_error(q{Usage: has 'name' => ( key => value, ... )})
		if @_ % 2; # odd number of arguments

	my %options = @_;
	my $writer  = $options{writer};
	my $trigger = $options{trigger} if defined $options{trigger} && !ref $options{trigger};
	my $builder = $options{builder} && !ref $options{builder};
	my $check   = delete $options{_check};
	my $isa;

	if ($check) {
		$isa = $options{isa};
		$isa =~ s/Maybe\[(.+)]/$1/g;
		$isa =~ s/\[.+]//;
		if (!$options{trigger}) {
			$options{trigger} = sub { shift->_check($isa, @_) };
		}
		elsif (!$trigger) {
			$options{trigger} = sub { &{$options{trigger}}; shift->_check($isa, @_) };
		}
	}

	for my $real_name (ref $name ? @$name : $name) {
		my $name = $real_name;
		$options{reader} = $real_name;

		if (substr($name, 0, 1) eq "_") {
			substr($name, 0, 1) = "";
			$options{writer} = "_set_$name" if $writer;
		}
		else {
			$options{writer} = "set_$name" if $writer;
		}

		if ($builder) { $options{builder} = "_${name}_builder" }
		if ($trigger) {
			my $trigger = \&{"${trigger}::_${name}_trigger"};
			if ($check) {
				$options{trigger} = sub { &$trigger; shift->_check($isa, @_) };
			}
			else {
				$options{trigger} = $trigger;
			}
		}

		$meta->add_attribute( $real_name, %options );
	}

	return;
}

sub ro  { splice @_, 1, 0, required => 1,                    'isa'; goto &has }
sub ro_ { splice @_, 1, 0, required => 1, init_arg => undef, 'isa'; goto &has }
sub rw  { splice @_, 1, 0, writer   => 1,                    'isa'; goto &has }
sub rw_ { splice @_, 1, 0, writer   => 1, init_arg => undef, 'isa'; goto &has }

sub required () { required => 1 }
sub weak_ref () { weak_ref => 1 }
sub builder  () { builder  => 1 }
sub lazy     () { lazy     => 1 }
sub check    () { _check   => 1 }
sub trigger (;$) {
	if (@_) {
		return trigger => $_[0];
	}
	return trigger => scalar caller;
}

# Delayed with processing
sub with {
	no strict;
	@{caller.'::_WITH'} = @_;
}

1;
