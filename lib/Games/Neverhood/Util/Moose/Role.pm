package Games::Neverhood::Util::Moose::Role;

use 5.01;
my @exports; BEGIN { @exports = qw/ extends has before after around requires / }
use Mouse::Role @exports;
use Mouse::Exporter ();

# Mouse::Exporter->setup_import_methods(
# 	as_is => [ @exports, '_with' ],
# 	also => [ 'Games::Neverhood::Util::Moose' ],
# );

# *init_meta = \&Mouse::Role::init_meta;
# *_with = \&Mouse::Role::with;

1;
