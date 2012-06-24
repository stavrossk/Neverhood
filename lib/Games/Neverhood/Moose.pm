# Games::Neverhood::Moose - imports Moose stuff as well as my own stuff
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use 5.01;
package Games::Neverhood::Moose;
use Mouse ();
use Mouse::Exporter;
use Carp ();
use File::Spec ();
use Games::Neverhood ();

our $Extra_Subs = [
	\&private, \&private_set,
	\&rw, \&ro,
	\&Any, \&Item, \&Bool, \&Maybe, \&Undef, \&Defined, \&Value, \&Str, \&Num, \&Int, \&ClassName, \&RoleName, \&Ref, \&ScalarRef, \&ArrayRef, \&HashRef, \&CodeRef, \&RegexpRef, \&GlobRef, \&FileHandle, \&Object,
	\&debug, \&error,
	\&data_file, \&data_dir, \&share_file, \&share_dir,
];

Mouse::Exporter->setup_import_methods(
	as_is => $Extra_Subs,
	also => 'Mouse',
);

sub private {
	my ($method) = shift;
	@_ = (
		$method,
		is => 'rw',
		init_arg => undef,
		@_
	);
	goto \&Mouse::has;
}
sub private_set {
	my ($method) = shift;
	Carp::croak("private_set doesn't work with arrayref method") if ref $method;
	@_ = (
		$method,
		is => 'ro',
		writer => "_set_$method",
		init_arg => undef,
		@_
	);
	goto \&Mouse::has;
}

sub rw { is => 'rw', @_ }
sub ro { is => 'ro', @_ }

sub Any        ()  { isa => 'Any' }
sub Item       ()  { isa => 'Item' }
sub Bool       ()  { isa => 'Bool' }
sub Maybe     (;$) { isa => @_ ? 'Maybe[$_[0]]' : 'Maybe' }
sub Undef      ()  { isa => 'Undef' }
sub Defined    ()  { isa => 'Defined' }
sub Value      ()  { isa => 'Value' }
sub Str        ()  { isa => 'Str' }
sub Num        ()  { isa => 'Num' }
sub Int        ()  { isa => 'Int' }
sub ClassName  ()  { isa => 'ClassName' }
sub RoleName   ()  { isa => 'RoleName' }
sub Ref        ()  { isa => 'Ref' }
sub ScalarRef (;$) { isa => @_ ? "ScalarRef[$_[0]]" : 'ScalarRef' }
sub ArrayRef  (;$) { isa => @_ ? "ArrayRef[$_[0]]"  : 'ArrayRef' }
sub HashRef   (;$) { isa => @_ ? "HashRef[$_[0]]"   : 'HashRef' }
sub CodeRef    ()  { isa => 'CodeRef' }
sub RegexpRef  ()  { isa => 'RegexpRef' }
sub GlobRef    ()  { isa => 'GlobRef' }
sub FileHandle ()  { isa => 'FileHandle' }
sub Object     ()  { isa => 'Object' }

sub debug {
	return $Games::Neverhood::Debug unless @_;
	return unless $Games::Neverhood::Debug;

	my ($sub, $filename, $line) = _get_sub_filename_line();

	say STDERR sprintf "----- at %s(), %s line %d:", $sub, $filename, $line;
	say STDERR sprintf(shift, @_);
	return;
}
sub error {
	my ($sub, $filename, $line) = _get_sub_filename_line();

	say STDERR sprintf "%s at %s(), %s line %d", sprintf(shift, @_), $sub, $filename, $line;
	exit 1;
}
sub _get_sub_filename_line {
	my ($package, $filename, $line) = (caller 1);
	my ($sub)                       = (caller 2)[3];

	# removes the package name at the start of the sub name
	$sub =~ s/^\Q${package}::\E//;

	# might replace the full lib name from the filename with lib
	my $i = -1;
	1 until(++$i > $#INC or $filename =~ s/^\Q$INC[$i]\E/lib/);

	return($sub, $filename, $line);
}

sub data_file  { File::Spec->catfile($Games::Neverhood::Data_Dir,  @_) }
sub data_dir   { File::Spec->catdir ($Games::Neverhood::Data_Dir,  @_) }
sub share_file { File::Spec->catfile($Games::Neverhood::Share_Dir, @_) }
sub share_dir  { File::Spec->catdir ($Games::Neverhood::Share_Dir, @_) }

1;
