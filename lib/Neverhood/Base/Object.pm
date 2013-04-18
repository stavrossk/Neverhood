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
use Neverhood::Base;

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
	my $caller = caller;
	my $meta = $caller->meta;
	my $name = shift;

	$meta->throw_error(q{Usage: has 'name' => ( key => value, ... )})
		if @_ % 2; # odd number of arguments

	my %options = @_;
	my $reader  = $options{reader};
	my $writer  = $options{writer};
	my $builder = $options{builder};
	my $check   = delete $options{_check};
	my $isa;
	if ($check or !$builder and !exists $options{default}) {
		$isa = $options{isa};
		1 while $isa =~ s/^Maybe\[(.+)]/$1/;
		$isa =~ s/\[.+]//;

		if (!$builder and !exists $options{default}) {
			if ($isa eq 'ArrayRef') {
				$options{default} = sub { [] };
			}
			elsif ($isa eq 'HashRef') {
				$options{default} = sub { {} };
			}
		}
	}

	my $trigger_coderef = delete $options{_trigger};
	my $trigger = '';
	$trigger = '$self->$trigger_coderef($new, $old); ' if $trigger_coderef and ref $trigger_coderef;

	if ($check) {
		$check = '$self->invalidate if ';
		$check .= do {
			given ($isa) {
				when (Bool)               {   '$new      xor  $old' }
				when ([Int, Num])         {  '($new//0)  !=  ($old//0)' }
				when (Str)                {  '($new//"") ne  ($old//"")' }
				when ([Palette, Surface]) { '${$new//\0} != ${$old//\0}' }
				when ([Rect, RectX])      {
					'!Neverhood::CUtil::rects_equal($new//SDL::Rect->new(0,0,0,0), $old//SDL::Rect->new(0,0,0,0))';
				}
				default { $meta->throw_error("Invalidator check on unsupported type: $isa") }
			}
		};
		$check .= '; ';

		if (!$trigger_coderef or ref $trigger_coderef) {
			$trigger .= $check;
		}
	}

	for my $name (ref $name ? @$name : $name) {
		$options{reader} = $reader.$name;
		$options{writer} = $writer."set_$name" if defined $writer;
		$options{builder} = "_build_$name" if $builder and !ref $builder;

		$meta->add_attribute( $name, \%options );

		if ($trigger_coderef and !ref $trigger_coderef) {
			$trigger = "\$self->${caller}::_trigger_$name(\$new, \$old); ";
			$trigger .= $check if defined $check;
		}
		if (length $trigger) {
			my $code = 'sub { '
				. 'my $orig = shift; '
				. 'my ($self, $new) = @_; '
				. "my \$old = \$_[0]->$options{reader}; "
				. '&$orig; '
				. $trigger
				. '}'
			;

			$meta->add_around_method_modifier($options{writer} => eval $code);
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

no Neverhood::Base;
1;
