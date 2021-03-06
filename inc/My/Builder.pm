package My::Builder;
use strict;
use warnings;
use base 'Module::Build';
use autodie ':all';

$ENV{SDL_VIDEODRIVER} = 'dummy';
$ENV{SDL_AUDIODRIVER} = 'dummy';

=pod

=head1 ACTIONS

=over

=item uninstall

[version 0.01] (Blaise Roth, experimental)

This action will find the .packlist file made when the distribution was
installed and attempt to delete all files listed in it. The process of finding
the .packlist file requires the module to be installed, so you will need to
install the distribution again to reatempt an uninstall.

=back

=cut

sub ACTION_uninstall {
	eval { require Games::Neverhood };
	$! and leave("Games::Neverhood wouldn't load: $@. Maybe install before uninstalling?");
	require File::ShareDir;
	require File::Spec;
	my $dir = File::ShareDir::module_dir('Games::Neverhood');
	my $packlist = File::Spec->catfile($dir, '.packlist');
	open LIST, ">>$packlist"; #Just makin' sure we can write in it later
	open LIST, $packlist;
	my $leftover;
	my $total = my $deleted = 0;
	print "Deleting all files listed in $packlist\n";
	while(<LIST>) {
		chomp;
		no autodie;
		if(unlink) {
			$deleted++;
		}
		elsif(-e) {
			STDERR->print("Couldn't delete $_: $!\n");
			$leftover .= "$_\n";
		}
		else {
			$total--;
		}
		$total++;
	}
	if(defined $leftover and $deleted) {
		print "$deleted of $total files successfully deleted\n";
		print "Updating .packlist with remaining files\n";
		open LIST, ">$packlist";
		print LIST $leftover;
		print ".packlist updated with remaining files\n";
	}
	else {
		print "all files successfully deleted\n";
		if(do { no autodie; unlink $packlist }) {
			print ".packlist deleted\n";
		}
		else {
			open LIST, ">$packlist";
			print ".packlist emptied\n";
		}
	}
	close LIST;
}

sub leave {
	STDERR->print($_[0], "\n");
	exit;
}

1;
