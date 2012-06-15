#!/usr/bin/perl

# Build.PL - creates a build script to install Games::Neverhood
# Copyright (C) 2012  Blaise Roth
# See the LICENSE file for the full terms of the license.

use strict;
use warnings;
use Alien::SDL;
use ExtUtils::CBuilder;
use File::Spec;
use lib File::Spec->catdir('inc');
use My::Builder;

my @cflags = ExtUtils::CBuilder->new->split_like_shell( File::Spec->catfile('-I' . Alien::SDL->config('prefix'), 'include') );
my @lflags = ExtUtils::CBuilder->new->split_like_shell( Alien::SDL->config('libs', '-lSDL_mixer') );

my $build = My::Builder->new(
	module_name   => 'Games::Neverhood',
	dist_abstract => 'The Neverhood remade in SDL Perl',
	license       => 'GPL_2',
	requires => {
		'perl'           => 5.010,
		'SDL'            => 2.541,
		'Mouse'          => 0.93,
		'File::ShareDir' => 0,
	},
	configure_requires   => { 'Module::Build' => 0.34 },
	share_dir            => File::Spec->catdir('share'),
	extra_compiler_flags => \@cflags,
	extra_linker_flags   => \@lflags,
	include_dirs         => [ File::Spec->catdir('src') ],
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
