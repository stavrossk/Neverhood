# Games::Neverhood::Moose::Role - imports Moose::Role stuff as well as my own stuff
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
package Games::Neverhood::Moose::Role;
use Mouse::Role ();
use Mouse::Exporter;
use Games::Neverhood::Moose ();

Mouse::Exporter->setup_import_methods(
	as_is => $Games::Neverhood::Moose::Extra_Subs,
	also => 'Mouse::Role',
);

1;
