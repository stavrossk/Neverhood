=head1 NAME

Neverhood::ResourceKey - Just a class holding a string

=head1 SEE ALSO

L<Neverhood::Base::Declare>

=cut

use 5.01;
use strict;
use warnings;

package Neverhood::ResourceKey;

use overload
	'""' => sub { ${$_[0]} },
	fallback => 1,
;

sub new {
	my ($class, $key) = @_;
	bless \$key, $class;
}

1;
