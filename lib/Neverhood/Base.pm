=head1 NAME

Neverhood::Base - Exports Base modules and cleans them up

=cut

use 5.01;
use feature ();
use warnings;
use strict;

package Neverhood::Base;

# Because of the way Mouse::Exporter works, it's very
# important that the Base:: modules get used in the right order

# First comes Declare. It doesn't rely on anything
use Neverhood::Base::Declare ();

# Next comes Util. It also exports Declare
use Neverhood::Base::Util ();

# Next comes Object. It also exports Util
use Neverhood::Base::Object ();

# Last come Object::Class and Object::Role. They also export Object
use Neverhood::Base::Object::Class ();
use Neverhood::Base::Object::Role ();

# There are a few ways to import this module
# This hash remembers how each package imported it
# so that it can unimport correctly
my %imported;

sub import {
	my ($class, $group) = @_;
	my $caller = caller;

	my $imported;
	if (@_ < 2) {
		$imported = "Neverhood::Base::Util";
	}
	elsif ($group eq ':class') {
		$imported = "Neverhood::Base::Object::Class";
	}
	elsif ($group eq ':role') {
		$imported = "Neverhood::Base::Object::Role";
	}
	else {
		Carp::croak("$class doesn't export '$group'");
	}
	$imported->import({into => $caller});
	$imported{$caller} = $imported;

	Neverhood::Base::Declare->setup_declarators($caller);
	@_ = qw/feature :5.10/;
	goto(feature->can('import'));
};

sub unimport {
	my ($class) = @_;
	my $caller = caller;

	return if !exists $imported{$caller};
	$imported{$caller}->unimport({into => $caller});
	delete $imported{$caller};

	Neverhood::Base::Declare->teardown_declarators($caller);
}

1;
