use 5.01;
use strict;
use warnings;
package Games::Neverhood::Scene::Test;

use parent qw/Games::Neverhood::Scene/;
use Games::Neverhood::Video;
use File::Spec;

use constant {
	fps => 24,
	cursor_type => 'sides_down',
};
sub sprites_list {
	[
		Games::Neverhood::Video->new(file => 73, dir => 'hd'),
	];
}

package Games::Neverhood::Scene::Test::test;
our @ISA = qw/Games::Neverhood::Sprite/;

use constant {
	file => 505,
	alpha => 0,
	pos => [255, 255],
};
sub palette { state $foo = Games::Neverhood::Scene::Test::background->new }

package Games::Neverhood::Scene::Test::background;
	our @ISA = qw/Games::Neverhood::Sprite/;
	use constant {
		file => 496,
	};

sub on_move {

}

1;