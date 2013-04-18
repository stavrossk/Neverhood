use lib 'lib';
use Neverhood;
use Neverhood::Base;

my $options = Neverhood::Options->new_from_config;
my $game = Neverhood->new($options);

my $res = Neverhood::ResourceMan->new;


