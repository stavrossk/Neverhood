#!/usr/bin/perl

# Build.PL - creates a build script to install Games::Neverhood
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Alien::SDL;
use ExtUtils::CBuilder;
use File::Spec;
use lib File::Spec->catdir('inc');
use My::Builder;

my @cflags = ExtUtils::CBuilder->new->split_like_shell( File::Spec->catfile('-I' . Alien::SDL->config('prefix'), 'include') );
my @lflags = ExtUtils::CBuilder->new->split_like_shell( Alien::SDL->config('libs', '-lSDL_mixer') );

my @xs_files = qw/
	MusicResource
	PaletteResource
	ResourceEntry
	SequenceResource
	SmackerResource
	SoundResource
	SpriteResource
	SurfaceUtil
/;

sub xs_files {
	my ($name) = @_;
	$name = "$name.xs";
	File::Spec->catfile('src', $name) => File::Spec->catfile('lib', 'Games', 'Neverhood', $name);
}

my $build = My::Builder->new(
	module_name   => 'Games::Neverhood',
	dist_abstract => 'The Neverhood remade in SDL Perl',
	license       => 'gpl',
	requires => {
		'perl'                      => 5.01,
		'SDL'                       => 2.541,
		'File::ShareDir'            => 1.03,
		'ExtUtils::ParseXS'         => 3.01,
		'Moose'                     => 2.06,
		'MooseX::Declare'           => 0.34,
		'MooseX::StrictConstructor' => 0.19,
		'Getopt::Long::Descriptive' => 0.09,
	},
	configure_requires   => { 'Module::Build' => 0.34 },
	share_dir            => File::Spec->catdir('share'),
	extra_compiler_flags => [ @cflags ],
	extra_linker_flags   => [ @lflags ],
	xs_files             => { map xs_files($_), @xs_files },
	include_dirs         => [ File::Spec->catdir('src') ],
	c_source             => [ File::Spec->catdir('src') ],
	typemap_files        => { 'typemap' => File::Spec->catfile('lib', 'Games', 'Neverhood', 'typemap') },
	dynamic_config       => 1,
	add_to_cleanup => [
		File::Spec->catfile('MANIFEST'),
		File::Spec->catfile('MANIFEST.bak'),
		File::Spec->catfile('META.yml'),
		File::Spec->catfile('META.json'),
		File::Spec->catfile('lib', 'Games', 'Neverhood', 'typemap'),
	],
	meta_merge => {
		resources => {
			license    => 'http://www.gnu.org/licenses/gpl-2.0.html',
			repository => 'http://github.com/Blaizer/Neverhood',
		},
	},
);

$build->add_build_element('typemap');
$build->create_build_script;
