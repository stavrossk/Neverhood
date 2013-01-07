# Games::Neverhood::Moose - sets up MooseX::Declare to export a bunch of subs into all my classes and roles
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Games::Neverhood::Moose;

use 5.01;
use strict;
use warnings;

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
use YAML::XS ();

# use all the SDL stuff we need here
# then you only need to import constants in each class
use SDL ();
use SDL::Constants ();
use SDLx::App ();
use SDL::Video ();
use SDL::Rect ();
use SDLx::Rect ();
use SDL::Color ();
use SDL::Palette ();
use SDL::Event ();
use SDL::Events ();
use SDL::Mixer ();
use SDL::Mixer::Channels ();
use SDL::Mixer::MixChunk ();
use SDL::Mixer::Music ();
use SDL::GFX::Rotozoom ();
use SDL::CD ();
use SDL::CDROM ();

# use all my XS stuff here also
# can't use the perl stuff because that needs to be done after use Games::Neverhood::Moose
BEGIN {
	XSLoader::load('Games::Neverhood::SurfaceUtil');
	XSLoader::load('Games::Neverhood::ResourceEntry');
	XSLoader::load('Games::Neverhood::SpriteResource');
	XSLoader::load('Games::Neverhood::PaletteResource');
	XSLoader::load('Games::Neverhood::SequenceResource');
	XSLoader::load('Games::Neverhood::SoundResource');
	XSLoader::load('Games::Neverhood::MusicResource');
	XSLoader::load('Games::Neverhood::SmackerResource');

	# have to modify @ISA here because XSLoader unceremoniously clobbers it
	push @Games::Neverhood::PaletteResource::ISA, 'SDL::Palette';
	push @Games::Neverhood::SoundResource::ISA,   'SDL::Mixer::MixChunk';
}

sub do_import {
	my $moose = shift;

	my ($import) = Moose::Exporter->build_import_methods(
		with_meta => [
			qw( rw ro pvt rpvt pvt_arg rpvt_arg rwpvt ),
		],
		as_is => [
			qw ( required weak_ref trigger builder ),
			qw ( Maybe Bool Value Str Num Int ClassName RoleName Ref ScalarRef ArrayRef HashRef CodeRef RegexpRef GlobRef FileHandle Object ),
			qw ( Rect Surface SceneName Palette ),
			qw ( debug error debug_stack ),
			qw ( cat_file cat_dir data_file data_dir share_file share_dir ),
			\&maybe, \&List::Util::max, \&List::Util::min, \&unindent, \&Scalar::Util::weaken,
			qw ( store retrieve ),
			qw ( is_class_loaded ),
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

# Moose::has stuff
sub has {
	my $meta = shift;
	my $names = shift;

	error("Odd number of args given to has: ".join ', ', @_)
		if @_ % 2 == 1;

	my $attrs = ref $names eq 'ARRAY' ? $names : [ $names ];

	my %options = ( definition_context => Moose::Util::_caller_info(), @_ );
	my $reader = $options{reader};
	my $writer = $options{writer};
	my $trigger = $options{trigger} if defined $options{trigger} && !ref $options{trigger};
	my $builder = $options{builder} && !ref $options{builder};

	for my $name (@$attrs) {
		$options{reader} = $reader.$name;
		$options{writer} = $writer."set_$name" if defined $options{writer};

		if ($trigger) { $options{trigger} = \&{$trigger."::_${name}_trigger"} }
		if ($builder) { $options{builder} =               "_${name}_builder" }

		$meta->add_attribute( $name, %options );
	}
}
sub rw       { splice @_, 2, 0, reader => "",  writer => "",                     'isa'; goto &has }
sub ro       { splice @_, 2, 0, reader => "",                                    'isa'; goto &has }
sub pvt      { splice @_, 2, 0, reader => "_", writer => "_", init_arg => undef, 'isa'; goto &has }
sub rpvt     { splice @_, 2, 0, reader => "",  writer => "_", init_arg => undef, 'isa'; goto &has }
sub pvt_arg  { splice @_, 2, 0, reader => "_", writer => "_",                    'isa'; goto &has }
sub rpvt_arg { splice @_, 2, 0, reader => "",  writer => "_",                    'isa'; goto &has }
sub rwpvt    { splice @_, 2, 0, reader => "",  writer => "",  init_arg => undef, 'isa'; goto &has }

sub required ()  { required => 1 }
sub weak_ref ()  { weak_ref => 1 }
sub trigger (;$) {
	if (@_) {
		return trigger => $_[0];
	}
	return trigger => scalar caller,
}
sub builder () { builder => 1 }

# builtin type constraints
sub Maybe     (;$) { @_ ? sprintf('Maybe[%s]', shift) : 'Maybe' }
sub Bool       ()  { 'Bool' }
sub Value      ()  { 'Value' }
sub Str        ()  { 'Str' }
sub Num        ()  { 'Num' }
sub Int        ()  { 'Int' }
sub ClassName  ()  { 'ClassName' }
sub RoleName   ()  { 'RoleName' }
sub Ref       (;$) { @_ ? sprintf('Ref[%s]',       shift) : 'Ref' }
sub ScalarRef (;$) { @_ ? sprintf('ScalarRef[%s]', shift) : 'ScalarRef' }
sub ArrayRef  (;$) { @_ ? sprintf('ArrayRef[%s]',  shift) : 'ArrayRef', default => sub { [] } }
sub HashRef   (;$) { @_ ? sprintf('HashRef[%s]',   shift) : 'HashRef',  default => sub { {} } }
sub CodeRef    ()  { 'CodeRef' }
sub RegexpRef  ()  { 'RegexpRef' }
sub GlobRef    ()  { 'GlobRef' }
sub FileHandle ()  { 'FileHandle' }
sub Object     ()  { 'Object' }

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

sub cat_file   { File::Spec->catfile(@_) }
sub cat_dir    { File::Spec->catdir (@_) }
sub data_dir   { File::Spec->catdir ($;->_options->data_dir,  @_) }
sub share_dir  { File::Spec->catdir ($;->_options->share_dir, @_) }
sub data_file  { File::Spec->catfile($;->_options->data_dir,  @_) }
sub share_file { File::Spec->catfile($;->_options->share_dir, @_) }

# returns what it was given, but returns an empty list if the value is undefined
sub maybe {
	if    (@_ == 2) { return @_ if defined $_[1] }
	elsif (@_ == 1) { return @_ if defined $_[0] }
	else { error("maybe() needs 1 or 2 arguments but was called with %d", scalar @_) }
	return;
}

# for use on heredocs
sub unindent {
	my ($str) = @_;
	$str =~ s/^\t+//gm;
	$str;
}

# serialization methods
sub store    { goto &YAML::XS::DumpFile }
sub retrieve { goto &YAML::XS::LoadFile }

# type constriants
class_type 'Rect'    => { class => 'SDL::Rect' };    sub Rect    () { 'Rect' }
class_type 'Surface' => { class => 'SDL::Surface' }; sub Surface () { 'Surface' }
class_type 'Palette' => { class => 'SDL::Palette' }; sub Palette () { 'Palette' }

subtype 'SceneName' =>
	as Str,
	# where { is_class_loaded('Games::Neverhood::Scene::' . $_) },
; sub SceneName () { 'SceneName' }

1;
