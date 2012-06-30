# nothing to see here

package Games::Neverhood::Moose::Role;
use Games::Neverhood::Moose;

sub import {
	if(caller(0) =~ /^Games::Neverhood/) {
		unshift @_, 'Moose::Role';
		goto(Games::Neverhood::Moose->can('do_import'));
	}
	else {
		goto(Moose::Role->can('import'));
	}
}

1;
