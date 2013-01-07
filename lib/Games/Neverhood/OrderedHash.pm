# OrderedHash - a hash with an order
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use warnings;
use strict;

package Games::Neverhood::OrderedHash;

use Method::Signatures;

use constant {
	TIEDHASH  => 0,
	TIEDARRAY => 1,
	ORDER     => 0,
	HASH      => 1,
};
use parent 'Exporter';
BEGIN {
	our @EXPORT_OK = (qw/TIEDHASH TIEDARRAY ORDER HASH/);
}

use Games::Neverhood::OrderedHash::TiedHash;
use Games::Neverhood::OrderedHash::TiedArray;

use overload
	'%{}' => sub { no overloading; $_[0][TIEDHASH] },
	'@{}' => sub { no overloading; $_[0][TIEDARRAY] },

	fallback => 1,
;

method new ($class: Maybe[ArrayRef] $order?, @hash) {
	if ($order) {
		Carp::confess("Order list must not have dups")
			if keys %{{map {$_ => undef} @$order}} != @$order;
	}
	else {
		$order = [];
	}
	my $hash = {};
	$class = ref $class || $class;
	# The two ties must share the same order and hash, but must use unique arrayrefs for destruction to work correctly
	tie my %tie, 'Games::Neverhood::OrderedHash::TiedHash',  [$order, $hash];
	tie my @tie, 'Games::Neverhood::OrderedHash::TiedArray', [$order, $hash];

	if (@hash % 2) {
		Carp::cluck('Odd number of elements in ordered hash');
		push @_, undef;
	}
	for (my $i = 0; $i < @hash; $i += 2) {
		$tie{$hash[$i]} = $hash[$i+1];
	}

	bless [\%tie, \@tie], $class;
}
method DESTROY {
	no overloading;
	# delete the tiedhash to break reference loop
	delete $self->[TIEDHASH];
}

1;
