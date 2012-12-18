# Games::Neverhood::Moose - sets up MooseX::Declare to export a bunch of subs into all my classes and roles
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
package Games::Neverhood::Moose;

use Moose ();
use Moose::Role ();
use Moose::Exporter ();
use MooseX::StrictConstructor ();
use Moose::Util::TypeConstraints;
use Class::Load 'is_class_loaded';
use XSLoader ();
use Carp ();
use File::Spec ();
use Scalar::Util ();
use List::Util ();

# use all the SDL stuff we need here
# then you only need to import constants in each class
use SDL ();
use SDL::Constants ();
use SDLx::App ();
use SDL::Video ();
use SDL::Rect ();
use SDLx::Rect ();
use SDL::Color ();
use SDL::Event ();
use SDL::Events ();
use SDL::Mixer ();
use SDL::Mixer::Channels ();
use SDL::Mixer::Music ();
use SDL::RWOps ();
use SDL::GFX::Rotozoom ();

# use all my XS stuff here also
# can't use the perl stuff because that needs to be done after use Games::Neverhood::Moose
BEGIN {
	XSLoader::load('Games::Neverhood::AudioVideo');
	XSLoader::load('Games::Neverhood::SurfaceUtil');
	XSLoader::load('Games::Neverhood::ResourceEntry');
	XSLoader::load('Games::Neverhood::SpriteResource');
	XSLoader::load('Games::Neverhood::SequenceResource');
	XSLoader::load('Games::Neverhood::SoundResource');
	XSLoader::load('Games::Neverhood::MusicResource');
	XSLoader::load('Games::Neverhood::SmackerResource');
}

sub do_import {
	my $moose = shift;

	my ($import) = Moose::Exporter->build_import_methods(
		as_is => [
			\&rw, \&ro, \&private, \&private_set, \&init_private_set,
			\&Any, \&Item, \&Bool, \&Maybe, \&Undef, \&Defined, \&Value, \&Str, \&Num, \&Int, \&ClassName, \&RoleName, \&Ref, \&ScalarRef, \&ArrayRef, \&HashRef, \&CodeRef, \&RegexpRef, \&GlobRef, \&FileHandle, \&Object, \&Rect, \&Surface, \&SceneName,
			\&debug, \&error, \&debug_stack,
			\&data_file, \&data_dir, \&share_file, \&share_dir,
			\&maybe, \&List::Util::max, \&List::Util::min, \&unindent, \&Scalar::Util::weaken,
		],
		also => [$moose, 'MooseX::StrictConstructor'],
	);

	$import->($_[0] => {into_level => 1});
};

{
	# redefining subs! hacky but it works!
	no warnings 'redefine';
	*MooseX::Declare::Syntax::Keyword::Class::import_symbols_from = sub { 'Games::Neverhood::Moose::Class' };
	*MooseX::Declare::Syntax::Keyword::Role::import_symbols_from  = sub { 'Games::Neverhood::Moose::Role' };
}

sub rw          { is => 'rw', maybe(isa => shift), @_ }
sub ro          { is => 'ro', maybe(isa => shift), @_ }
sub private     { is => 'rw', maybe(isa => shift), init_arg => undef, @_ }
sub private_set {
	is => 'rw',
	maybe(isa => shift),
	init_arg => undef,
	trigger => sub {
		my $sub_1 = (caller 1)[0];
		my $sub_2 = (caller 2)[3];
		return unless defined $sub_2;
		$sub_2 =~ s/::[^:]+$//;

		Carp::confess("This method can only be set privately\n\n'", $sub_1, "' '", $sub_2, "'\n\n", join " ", (caller(1))[0,3],"\n\n", join " ", (caller(2))[0,3], "\n\n" )

		if defined $sub_2 and $sub_1 ne $sub_2;
	},
	@_
}
sub init_private_set {
	is => 'rw',
	maybe(isa => shift),
	trigger => sub {
		my $sub_1 = (caller 1)[0];
		my $sub_2 = (caller 2)[3];
		return unless defined $sub_2;
		$sub_2 =~ s/::[^:]+$//;

		Carp::confess("This method can only be set privately\n\n'", $sub_1, "' '", $sub_2, "'\n\n", join " ", (caller(1))[0,3],"\n\n", join " ", (caller(2))[0,3], "\n\n" )

		if defined $sub_2 and $sub_1 ne $sub_2;
	},
	@_
}

sub Any        () { 'Any' }
sub Item       () { 'Item' }
sub Bool       () { 'Bool' }
sub Maybe         { @_ ? sprintf('Maybe[%s]', shift) : 'Maybe' }
sub Undef      () { 'Undef' }
sub Defined    () { 'Defined' }
sub Value      () { 'Value' }
sub Str        () { 'Str' }
sub Num        () { 'Num' }
sub Int        () { 'Int' }
sub ClassName  () { 'ClassName' }
sub RoleName   () { 'RoleName' }
sub Ref        () { 'Ref' }
sub ScalarRef     { @_ ? sprintf('ScalarRef[%s]', shift) : 'ScalarRef', @_ }
sub ArrayRef      { @_ ? sprintf('ArrayRef[%s]',  shift) : 'ArrayRef',  @_, default => sub { [] } }
sub HashRef       { @_ ? sprintf('HashRef[%s]',   shift) : 'HashRef',   @_, default => sub { {} } }
sub CodeRef    () { 'CodeRef' }
sub RegexpRef  () { 'RegexpRef' }
sub GlobRef    () { 'GlobRef' }
sub FileHandle () { 'FileHandle' }
sub Object     () { 'Object' }

sub Rect      () { 'Rect' }
sub SceneName () { 'SceneName' }
sub Surface   () { 'Surface' }

sub debug {
	return $;->_options->debug unless @_;
	return unless $;->_options->debug;

	my ($sub, $filename, $line) = _get_sub_filename_line();

	say STDERR sprintf "----- at %s(), %s line %d:", $sub, $filename, $line;
	say STDERR sprintf(shift, @_);
	return;
}
sub debug_stack {
	return $;->_options->debug unless @_;
	return unless $;->_options->debug;
	say STDERR sprintf "-----";
	Carp::cluck(sprintf shift, @_);
}
sub error {
	say STDERR sprintf "-----";
	Carp::confess(sprintf shift, @_);
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

sub data_dir   { File::Spec->catdir ($;->_options->data_dir,  @_) }
sub share_dir  { File::Spec->catdir ($;->_options->share_dir, @_) }
sub data_file  { File::Spec->catfile($;->_options->data_dir,  @_) }
sub share_file { File::Spec->catfile($;->_options->share_dir, @_) }

# return a key-value pair only if the value is defined
sub maybe {
	if(@_ == 2) { return @_ if defined $_[1] }
	else { error("maybe() needs 2 arguments but was called with %s", scalar @_) }
	return;
}

# for use on heredocs
sub unindent {
	my ($str) = @_;
	$str =~ s/^\t+//gm;
	$str;
}

subtype Rect =>
	as Object,
	where { $_->isa('SDL::Rect') },
;
subtype Surface =>
	as Object,
	where { $_->isa('SDL::Surface') },
;
subtype SceneName =>
	as Str,
	# where { is_class_loaded('Games::Neverhood::Scene::' . $_) },
;

1;
