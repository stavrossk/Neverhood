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
		qw( ro rw rw_ pvt ),
		qw( check ),
		# qw( required ),
		# qw( weak_ref lazy_build ),
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
	my $reader  = $options{reader};
	my $writer  = $options{writer};
	my $builder = $options{builder};
	my $check   = delete $options{_check};
	my $trigger = delete $options{_trigger};
	my ($trigger_name, $trigger_coderef);
	if ($trigger) {
		ref $trigger ? $trigger_coderef : $trigger_name = $trigger;
		$trigger = '';
	}

	if ($trigger_coderef) {
		$trigger = '$self->$trigger_coderef(@_); ';
	}
	if ($check) {
		my $isa = $options{isa};
		1 while $isa =~ s/^Maybe\[(.+)]/$1/;
		$isa =~ s/\[.+]//;
		$check = "\$self->_check('$isa', \@_); ";
		if (!$trigger_name) {
			$trigger .= $check;
		}
	}

	for my $name (ref $name ? @$name : $name) {
		$options{reader} = $reader.$name;
		$options{writer} = $writer."set_$name" if defined $writer;

		if ($builder) { $options{builder} = "_build_$name" }

		$meta->add_attribute( $name, \%options );

		if ($trigger_name) {
			$trigger = "\$self->_changing_$name(\@_); ";
			$trigger .= $check if defined $check;
		}
		if (defined $trigger) {
			my $code = 'sub { '
				. 'my $orig = shift; '
				. 'my $self = shift; '
				. "my \$old = \$self->$options{reader}; "
				. '$self->$orig(@_); '
				. 'push @_, $old; '
				. $trigger
				. "}"
			;

			$code = eval $code || Carp::croak("$@ in code:\n$code");
			$meta->add_around_method_modifier($options{writer} => $code);
		}
	}

	return;
}

sub ro  { splice @_, 1, 0, reader => "",  required => 1,                    'isa'; goto &has }
sub rw  { splice @_, 1, 0, reader => "",  writer => "",                     'isa'; goto &has }
sub rw_ { splice @_, 1, 0, reader => "",  writer => "",  init_arg => undef, 'isa'; goto &has }
sub pvt { splice @_, 1, 0, reader => "_", writer => "_", init_arg => undef, 'isa'; goto &has }

sub check    () { _check   => 1 }
sub required () { required => 1 }
sub weak_ref () { weak_ref => 1 }
sub lazy_build () { lazy => 1, builder => 1 }

1;
