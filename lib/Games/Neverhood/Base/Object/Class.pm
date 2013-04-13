package Games::Neverhood::Base::Object::Class;

use 5.01;
my @exports; BEGIN { @exports = qw/ extends has before after around / }
use Mouse @exports;
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [ @exports ],
	also => [ 'Games::Neverhood::Base::Object' ],
);

BEGIN {
	*init_meta = \&Mouse::init_meta;
}

1;
