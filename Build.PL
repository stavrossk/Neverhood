#!/usr/bin/env perl
# Build.PL - creates a build script to install Neverhood
# Copyright (c) 2013 Blaise Roth

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.

use 5.01;
use strict;
use warnings;
use ExtUtils::CBuilder;
use File::Spec;
use File::Basename 'fileparse';

use lib File::Spec->catdir('inc');
use My::Build;

eval { require Alien::SDL; 1 } or die <<'ERROR';
Build.PL requires Alien::SDL to be installed. Maybe try:
perl -MCPAN -e "install Alien::SDL"
ERROR

my @cflags = ( ExtUtils::CBuilder->new->split_like_shell(File::Spec->catfile('-I' . Alien::SDL->config('prefix'), 'include')) );
my @lflags = ( ExtUtils::CBuilder->new->split_like_shell(Alien::SDL->config('libs', '-lSDL_mixer')) );
my @c_dirs = ( File::Spec->catdir('src') );

my @xs_files = map {
	my $file = $_;
	my ($name) = fileparse($file);
	$file => File::Spec->catfile('lib', 'Neverhood', $name);
} glob "src/*.xs";

my $build = My::Build->new(
	module_name   => 'Neverhood',
	license       => 'perl',
	configure_requires   => {
		'perl'          => 5.01,
		'Module::Build' => 0.34,
		'Alien::SDL'    => 1.438,
	},
	requires => {
		'perl'                      => 5.01,
		'SDL'                       => 2.541, # raise me
		'Mouse'                     => 1.02,
		'File::ShareDir'            => 1.03,
		'YAML::XS'                  => 0.37,
		'Method::Signatures'        => 20121201,
		'B::Hooks::EndOfScope'      => 0.12,
	},
	share_dir            => File::Spec->catdir('share'),
	extra_compiler_flags => [ @cflags ],
	extra_linker_flags   => [ @lflags ],
	xs_files             => { @xs_files },
	include_dirs         => [ @c_dirs ],
	c_source             => [ @c_dirs ],
	typemap_files        => { 'typemap' => File::Spec->catfile('lib', 'Neverhood', 'typemap') },
	dynamic_config       => 1,
	add_to_cleanup => [
		File::Spec->catfile('MANIFEST'),
		File::Spec->catfile('MANIFEST.bak'),
		File::Spec->catfile('META.yml'),
		File::Spec->catfile('META.json'),
		File::Spec->catfile('lib', 'Neverhood', 'typemap'),
		File::Spec->catfile('compilet_def.old'),
	],
	meta_merge => {
		resources => {
			license    => 'http://dev.perl.org/licenses/',
			repository => 'http://github.com/Blaizer/Neverhood',
		},
	},
);

$build->add_build_element('typemap');
$build->create_build_script;
