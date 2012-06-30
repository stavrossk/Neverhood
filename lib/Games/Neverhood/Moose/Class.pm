# nothing to see here

package Games::Neverhood::Moose::Class;
use Games::Neverhood::Moose;

sub import {
	if(caller(0) =~ /^Games::Neverhood/) {
		unshift @_, 'Moose';
		goto(Games::Neverhood::Moose->can('do_import'));
	}
	else {
		goto(Moose->can('import'));
	}
}

1;
