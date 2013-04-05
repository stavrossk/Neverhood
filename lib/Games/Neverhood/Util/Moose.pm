# Games::Neverhood::Util::Moose
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use strict;
use warnings;

package Games::Neverhood::Util::Moose;
use Moose ();
use Moose::Role ();
use Moose::Exporter ();

Moose::Exporter->setup_import_methods(
	with_meta => [
		qw( rw ro pvt rpvt wpvt rwpvt pvt_arg rpvt_arg ropvt ),
	],
	as_is => [
		qw( required weak_ref builder check trigger ),
	],
);

# attribute declaration customised
sub has {
	my $meta = shift;
	my $names = shift;

	error("Odd number of args given to has: ".join ', ', @_)
		if @_ % 2 == 1;

	my $attrs = ref $names eq 'ARRAY' ? $names : [ $names ];

	# this is undocumented, and has recently changed. Uh oh
	my %context = Moose::Util::_caller_info();
	my %options = ( definition_context => \%context, @_ );

	my $reader  = $options{reader};
	my $writer  = $options{writer};
	my $trigger = $options{trigger} if defined $options{trigger} && !ref $options{trigger};
	my $builder = $options{builder} && !ref $options{builder};
	my $check   = delete $options{_check};

	for my $name (@$attrs) {
		$options{reader} = $reader.$name;
		$options{writer} = $writer."set_$name" if defined $options{writer};

		if ($trigger) { $options{trigger} = \&{$trigger."::_${name}_trigger"} }
		if ($builder) { $options{builder} =               "_${name}_builder" }
		if ($check) {
			my $isa = $options{isa};
			$isa =~ s/Maybe\[(.+)]/$1/g;
			$isa =~ s/\[.+]//;
			if ($trigger) {
				my $trigger = $options{trigger};
				$options{trigger} = sub { my $self = shift; $self->$trigger(@_); $self->_check($isa, @_) };
			}
			else {
				$options{trigger} = sub { my $self = shift; $self->_check($isa, @_) };
			}
		}

		$meta->add_attribute( $name, %options );
	}
}

sub rw       { splice @_, 2, 0, reader => "",  writer => "",                     'isa'; goto &has }
sub ro       { splice @_, 2, 0, reader => "",                                    'isa'; goto &has }
sub pvt      { splice @_, 2, 0, reader => "_", writer => "_", init_arg => undef, 'isa'; goto &has }
sub rpvt     { splice @_, 2, 0, reader => "",  writer => "_", init_arg => undef, 'isa'; goto &has }
sub wpvt     { splice @_, 2, 0, reader => "_", writer => "",  init_arg => undef, 'isa'; goto &has }
sub rwpvt    { splice @_, 2, 0, reader => "",  writer => "",  init_arg => undef, 'isa'; goto &has }
sub pvt_arg  { splice @_, 2, 0, reader => "_", writer => "_",                    'isa'; goto &has }
sub rpvt_arg { splice @_, 2, 0, reader => "",  writer => "_",                    'isa'; goto &has }
sub ropvt    { splice @_, 2, 0, reader => "_",                                   'isa'; goto &has }

sub required () { required => 1 }
sub weak_ref () { weak_ref => 1 }
sub builder  () { builder  => 1 }
sub check    () { _check   => 1 }
sub trigger (;$) {
	if (@_) {
		return trigger => $_[0];
	}
	return trigger => scalar caller;
}

1;
