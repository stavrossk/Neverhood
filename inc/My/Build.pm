use 5.01;
package My::Build;
use strict;
use warnings;
use base 'Module::Build';

=head1 ACTIONS

=item license

[version 0.02] (Blaise Roth)

This action will generate a copy of this distribution's license - The
GNU General Public License version 3. This requires Software::License to
be installed. It will write it into a file called LICENSE in the current
directory. BEWARE: it will overwrite the file if it already exists (if
it can).

=back

=cut

sub ACTION_license {
	require Software::License;
	require Software::License::GPL_3;
	require File::Spec;
	my $license = Software::License::GPL_3->new({
		holder => 'Blaise Roth',
	});
	open LICENSE, ">", File::Spec->catfile('LICENSE');
	print LICENSE $license->fulltext();
	say "LICENSE file created successfully";
}

1;
