# nothing to see here

package Games::Neverhood::Exports::MooseClass;
# use Games::Neverhood::Exports ();

sub import {
	if (caller =~ /^Games::Neverhood/) {
		goto(Games::Neverhood::Exports->can('import_with_moose'));
	}
	goto(Moose->can('import'));
}

1;
