package Games::Neverhood::Util::Moose::Class;

use 5.01;
my @exports; BEGIN { @exports = qw/ extends has before after around / }
use Mouse @exports;
use Mouse::Exporter ();
use Games::Neverhood::Util::Declare ();
use Games::Neverhood::Util ();

Mouse::Exporter->setup_import_methods(
	as_is => [ @exports ],
	also => [ 'Games::Neverhood::Util::Declare', 'Games::Neverhood::Util', 'Games::Neverhood::Util::Moose' ],
);

use subs qw/ init_meta /;
*init_meta = \&Mouse::init_meta;

1;
