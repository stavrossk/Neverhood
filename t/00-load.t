use 5.01;
use strict;
use warnings;
no warnings 'once';

use Test::More;

use_ok('Neverhood');

my $options = Neverhood::Options->new(
	fullscreen => 0,
	no_frame => 0,
);

isnt( $options->share_dir, undef, 'Have a share dir' );

Neverhood->new(options => $options);

isa_ok( $;, 'Neverhood', "Game object created" );

$;->init_app();
isa_ok( $;->app, 'SDL::Surface', "App created" );
is( $;->app, $;->app, "Getting the same app object every time" );

undef $;;
pass( "Game object destroyed" );

diag( "Testing Neverhood $Neverhood::VERSION, $^X $]" );

done_testing;

