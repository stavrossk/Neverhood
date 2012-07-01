use 5.01;
use strict;
use warnings;
no warnings 'once';

use Test::More;

use_ok('Games::Neverhood');

my $options = Games::Neverhood::Options->new(
	fullscreen => 0,
	no_frame => 0,
);

isnt( $options->share_dir, undef, 'Have a share dir' );

Games::Neverhood->new(options => $options);

isa_ok( $;, 'Games::Neverhood', "Game object created" );

$;->init_app();
isa_ok( $;->app, 'SDL::Surface', "App created" );
is( $;->app, $;->app, "Getting the same app object every time" );

undef $;;
pass( "Game object destroyed" );

undef $Games::Neverhood::App;
pass( "App destroyed" );

diag( "Testing Games::Neverhood $Games::Neverhood::VERSION, Perl $], $^X" );

done_testing;
