# nothing to see here

package Games::Neverhood::Util::MooseClass;
sub import {
	if (caller =~ /^Games::Neverhood/) {
		goto(Games::Neverhood::Util->can('import_with_moose'));
	}
	goto(Moose->can('import'));
}

1;
