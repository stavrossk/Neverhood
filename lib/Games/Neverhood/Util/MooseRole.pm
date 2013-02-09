# nothing to see here

package Games::Neverhood::Util::MooseRole;
sub import {
	if (caller =~ /^Games::Neverhood/) {
		goto(Games::Neverhood::Util->can('import_with_moose_role'));
	}
	goto(Moose::Role->can('import'));
}

1;
