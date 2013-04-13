=head1 NAME

Games::Neverhood::ResourceKey - Just a class holding a string

=head1 SEE ALSO

L<Games::Neverhood::Base::Declare>

=cut

use 5.01;
use strict;
use warnings;

package Games::Neverhood::ResourceKey;

use overload
	'""' => sub { ${+shift} },
	fallback => 1,
;

sub new {
	my ($class, $key) = @_;
	bless \$key, $class;
}

1;
