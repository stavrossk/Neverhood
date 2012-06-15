use 5.01;
use strict;
use warnings;
no warnings 'once';

use Test::More;

$Games::Neverhood::Fullscreen = 0;
$Games::Neverhood::No_Frame = 0;
use_ok('Games::Neverhood');

isnt( $Games::Neverhood::Share_Dir, undef, 'Have a share dir' );

Games::Neverhood->new();

isa_ok( $;, 'Games::Neverhood', "Game object created" );

$;->init_app();
isa_ok( $;->app, 'SDL::Surface', "App created" );
is( Games::Neverhood->app, $;->app, "Getting the same app object every time" );

undef $;;
pass( "Game object destroyed" );

undef $Games::Neverhood::App;
pass( "App destroyed" );

diag( "Testing Games::Neverhood $Games::Neverhood::VERSION, Perl $], $^X" );

done_testing;
