package Neverhood::Base::Object::Class;

use 5.01;
my @exports; BEGIN { @exports = qw/ extends before after around / }
use Mouse @exports;
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [ @exports ],
	also => [ 'Neverhood::Base::Object' ],
);

BEGIN {
	*init_meta = \&Mouse::init_meta;
}

1;
