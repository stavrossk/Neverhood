# nothing to see here

package Games::Neverhood::Exports::MooseRole;
# use Games::Neverhood::Exports ();

sub import {
	if (caller =~ /^Games::Neverhood/) {
		goto(Games::Neverhood::Exports->can('import_with_moose_role'));
	}
	goto(Moose::Role->can('import'));
}

1;
