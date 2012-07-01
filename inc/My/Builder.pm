use 5.01;
package My::Builder;
use strict;
use warnings;
use base 'Module::Build';

# So SDL doesn't go crazy on us when we require Games::Neverhood
$ENV{SDL_VIDEODRIVER} = 'dummy';
$ENV{SDL_AUDIODRIVER} = 'dummy';

=head1 ACTIONS

=item uninstall

[version 0.03] (Blaise Roth, experimental)

This action will find the .packlist file made when the distribution was
installed and attempt to delete all files listed in it. The process of
finding the .packlist file requires the module to be installed, so you
will need to install the distribution again to reattempt an uninstall.

WARNING: This operation is potentially dangerous if you have newlines in
your path to Perl's lib directory. As a precaution, if there are any
newlines found in any of the strings in C<@INC>, this command will
refuse to run. If you are sure there are no newlines messing up the
.packlist file then you can force the command to continue anyway by
specifying --force option.

=back

=cut

sub ACTION_uninstall {
	require Games::Neverhood;
	$@ and leave("Games::Neverhood wouldn't load: $@Maybe install before uninstalling?");
	require File::ShareDir;
	require File::Spec;
	my $dir = File::ShareDir::module_dir('Games::Neverhood');
	my $packlist = File::Spec->catfile($dir, '.packlist');

	unless(grep defined && $_ eq 'force', $_[0]->args()) {
		for(@INC) {
			leave(sprintf(<<'WARNING', $packlist)) if /\n/;
This operation is potentially dangerous because you have newlines in a
path to Perl's lib directory (strings in @INC). This could mess up the
.packlist file used by this action to uninstall the distribution. The
distribution's .packlist file is located at:
%s

If you are sure there are no newlines messing up the .packlist file then
you can force the command to continue anyway by specifying the --force
option.
WARNING
		}
	}

	use autodie ':all';
	open LIST, ">>", $packlist; #Just makin' sure we can write in it later
	open LIST, "<", $packlist;
	my $leftover;
	my $total = my $deleted = 0;
	say "Deleting all files listed in $packlist";
	while(<LIST>) {
		chomp;
		no autodie;
		if(unlink) {
			$deleted++;
		}
		elsif(-e) {
			say STDERR "Couldn't delete $_: $!";
			$leftover .= "$_\n";
		}
		else {
			$total--;
		}
		$total++;
	}
	if(defined $leftover and $deleted) {
		say "$deleted of $total files successfully deleted";
		say "Updating .packlist with remaining files";
		open LIST, ">", $packlist;
		print LIST $leftover;
		say ".packlist updated with remaining files";
	}
	else {
		say "all files successfully deleted";
		if(do { no autodie; unlink $packlist }) {
			say ".packlist deleted";
		}
		else {
			open LIST, ">", $packlist;
			say ".packlist emptied";
		}
	}
	close LIST;
}

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

sub leave {
	say STDERR $_[0];
	exit;
}

1;
