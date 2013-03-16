#!/usr/bin/env perl

# nhc.pl - shortcut script to build, install and run Neverhood
# It is more for testing purposes. --debug is specified by default
# specify --no-debug to turn debug off
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use strict;
use warnings;

use FindBin ();
use File::Spec ();
use Capture::Tiny ':all';

sub quote {
	state $q = $^O eq 'MSWin32' ? '"' : "'";
	my ($str) = @_;
	$str =~ s/\\/\\\\/g;
	$str =~ s/$q/\\$q/g if $q;
	return $q.$str.$q;
}

my $build = quote(File::Spec->catfile($FindBin::Bin, 'Build'));

tee_merged { system $^X, $build and exit 1 }
	=~ /collect2: ld returned 1 exit status|:\d+:\d+: warning:/ and exit 1;

system $^X, $build, 'install' and exit 1;

my $nhc = quote(File::Spec->catfile($FindBin::Bin, 'blib', 'script', 'nhc'));

exec $^X, $nhc, qw(--debug --normal-window), @ARGV;

