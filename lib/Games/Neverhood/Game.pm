package Games::Neverhood::Game;

# The class for Scene, Video and Menu to inherit from

use 5.01;
use strict;
use warnings;

use File::Spec ();

use Data::Dumper;

use overload
	'""'   => sub { ref($_[0]) =~ /^Games::Neverhood::(.*)/ and return $1; $_[0] },
	'0+'   => sub { $_[0] },
	'fallback' => 1,
;

our $Set;

sub set {
	my ($unset) = @_;
	if(defined $_[1]) {
		$Set = $_[1];
		return $unset;
	}
	return $unset unless defined $Set;

	my $set_name = "Games::Neverhood::" . $Set;
	undef $Set;

	eval "use $set_name" or die $@;
	no strict 'refs';
	my $set = ${$set_name};

	$unset->setdown->($unset, $set);
	$set->setup->($set, $unset);

	$Games::Neverhood::Scene = $set;
	undef ${ref $unset};
	undef $unset;

	$Games::Neverhood::App->dt(1 / $set->fps);
	$set;
}

1;