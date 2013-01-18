#!/usr/bin/perl

# Build.PL - creates a build script to install Games::Neverhood
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use strict;
use warnings;
use ExtUtils::CBuilder;
use File::Spec;
use File::Basename 'fileparse';
use File::Glob 'bsd_glob';
use lib File::Spec->catdir('inc');
use My::Builder;

eval { require Alien::SDL } or die <<'ERROR';
Build.PL requires Alien::SDL to be installed. Maybe try:
perl -MCPAN -e "install Alien::SDL"
ERROR

my @cflags = ExtUtils::CBuilder->new->split_like_shell( File::Spec->catfile('-I' . Alien::SDL->config('prefix'), 'include') );
my @lflags = ExtUtils::CBuilder->new->split_like_shell( Alien::SDL->config('libs', '-lSDL_mixer') );

my @xs_files = map {
	my $file = $_;
	my ($name) = fileparse($file);
	$file => File::Spec->catfile('lib', 'Games', 'Neverhood', $name);
} bsd_glob "src/*.xs";

my $build = My::Builder->new(
	module_name   => 'Games::Neverhood',
	license       => 'gpl',
	requires => {
		'perl'                      => 5.01,
		'SDL'                       => 2.541, # raise me
		'File::ShareDir'            => 1.03,
		'YAML::XS'                  => 0.37,
		'Moose'                     => 2.06,
		'MooseX::Declare'           => 0.34,
		'Method::Signatures'        => 20121201,
		'MooseX::Types'             => 0.31,
		'MooseX::StrictConstructor' => 0.19, # remove me at v1.0
	},
	configure_requires   => { 'Module::Build' => 0.34 },
	share_dir            => File::Spec->catdir('share'),
	extra_compiler_flags => [ @cflags ],
	extra_linker_flags   => [ @lflags ],
	xs_files             => { @xs_files },
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
			license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
			repository => 'http://github.com/Blaizer/Neverhood',
		},
	},
);

$build->add_build_element('typemap');
# $build->fix_shebang_line(File::Spec->catfile('bin', 'nhc')); # enable this when building dist only
$build->create_build_script;
