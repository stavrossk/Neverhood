package Neverhood::Base::Object::Role;

use 5.01;
my @exports; BEGIN { @exports = qw/ extends has before after around requires / }
use Mouse::Role @exports;
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [ @exports ],
	also => [ 'Neverhood::Base::Object' ],
);

BEGIN {
	*init_meta = \&Mouse::Role::init_meta;
}

1;
