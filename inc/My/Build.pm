use 5.01;
package My::Build;
use strict;
use warnings;
use base 'Module::Build';
use File::Spec;

=head1 ACTIONS

=over

=item license

[version 0.1] (Blaise Roth)

This action will generate a copy of this distribution's license. This requires
Software::License to be installed. It will write it into a file called LICENSE
in the current directory. BEWARE: it will overwrite the file if it already
exists (if it can). It will also print out the notice and URL for the license.

=cut

sub ACTION_license {
	require Software::License;
	require Software::License::Perl_5;
	my $license = Software::License::Perl_5->new({
		holder => 'Blaise Roth',
	});
	open LICENSE, ">", File::Spec->catfile('LICENSE');
	print LICENSE $license->fulltext();
	say $license->notice();
	say $license->url();
}

=item libclean

[version 0.01] (Blaise Roth)

This action will clean the generated .c, .o, .xs, and typemap files from the
lib/Neverhood directory. Any files that can't be removed will be silently
skipped.

=cut

sub ACTION_libclean {
	my $files = join " ", map {
		File::Spec->catfile('lib', 'Neverhood', $_);
	} (
		# '*.c',
		# '*.o',
		'*.xs',
		'typemap',
	);
	
	while(glob $files) {
		unlink;
	}
}

1;

=back

=cut
