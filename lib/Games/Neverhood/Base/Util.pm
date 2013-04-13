=head1 NAME

Neverhood::Base::Util - Common utility functions to export everywhere

=cut

use 5.01;
use strict;
use warnings;

package Neverhood::Base::Util;

use Mouse ();
use Mouse::Role ();
use Mouse::Exporter ();
use Mouse::Util::TypeConstraints;
use XSLoader ();
use Carp ();
use File::Spec ();
use Scalar::Util qw/ weaken blessed /;
use List::Util qw/ max min /;
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
# can't use the perl stuff because that needs to be done after use Neverhood::Base::Util
BEGIN {
	XSLoader::load 'Neverhood::CUtil';
	XSLoader::load 'Neverhood::ResourceEntry';
	XSLoader::load 'Neverhood::SpriteResource';
	XSLoader::load 'Neverhood::PaletteResource';
	XSLoader::load 'Neverhood::SequenceResource';
	XSLoader::load 'Neverhood::SoundResource';
	XSLoader::load 'Neverhood::MusicResource';
	XSLoader::load 'Neverhood::SmackerResource';

	# have to modify @ISA here because XSLoader unceremoniously clobbers it
	unshift @Neverhood::PaletteResource::ISA, 'SDL::Palette';
	unshift @Neverhood::SoundResource::ISA,   'SDL::Mixer::MixChunk';
}

Mouse::Exporter->setup_import_methods(
	as_is => [
		qw( debug error debug_stack ),
		qw( cat_file cat_dir data_file data_dir share_file share_dir ),
		qw( maybe unindent is_class_loaded ),
		qw( store retrieve ),
		qw( max min weaken blessed ),
		# qw( Item Maybe Value Bool Str Num Int ClassName RoleName Ref ScalarRef ArrayRef HashRef CodeRef RegexpRef GlobRef FileHandle Object ),
		# qw( Rect RectX Surface Palette ResourceKey SceneName ),
	],
	also => [ 'Neverhood::Base::Declare' ],
);

sub debug {
	return $;->_options->debug if !@_;
	return if !$;->_options->debug;

	my ($sub, $filename, $line) = _get_sub_filename_line();

	say STDERR sprintf "----- at %s(), %s line %d:", $sub, $filename, $line;
	say STDERR sprintf(shift, @_);
	return;
}
sub debug_stack {
	return $;->_options->debug if !@_;
	return if !$;->_options->debug;
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
	1 until ++$i > $#INC or $filename =~ s/^\Q$INC[$i]\E/lib/;

	return($sub, $filename, $line);
}

sub cat_file   { File::Spec->catfile(@_) }
sub cat_dir    { File::Spec->catdir (@_) }
sub data_file  { File::Spec->catfile($;->_options->data_dir,  @_) }
sub data_dir   { File::Spec->catdir ($;->_options->data_dir,  @_) }
sub share_file { File::Spec->catfile($;->_options->share_dir, @_) }
sub share_dir  { File::Spec->catdir ($;->_options->share_dir, @_) }

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
BEGIN {
	*store    = \&YAML::XS::DumpFile;
	*retrieve = \&YAML::XS::LoadFile;
}

# # class types
# class_type 'Rect',        { class => 'SDL::Rect' };                     sub Rect        () { 'SDL::Rect' }
# class_type 'RectX',       { class => 'SDLx::Rect' };                    sub RectX       () { 'SDLx::Rect' }
# class_type 'Surface',     { class => 'SDL::Surface' };                  sub Surface     () { 'SDL::Surface' }
# class_type 'Palette',     { class => 'SDL::Palette' };                  sub Palette     () { 'SDL::Palette' }
# class_type 'ResourceKey', { class => 'Neverhood::ResourceKey' }; sub ResourceKey () { 'Neverhood::ResourceKey' }

# # subtypes
# subtype 'SceneName',
# 	as Str,
# 	# where { is_class_loaded('Neverhood::Scene::' . $_) },
# ; sub SceneName () { 'SceneName' }

1;
