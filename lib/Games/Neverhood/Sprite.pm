# Sprite - drawable single image sprites
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use MooseX::Declare;

class Games::Neverhood::Sprite with Games::Neverhood::Drawable {
	use constant invalidator_checks => ( 'is_mirrored', 'x', 'y' );

	# public attributes

	has file        => ro Str, required => 1;
	has is_mirrored => rw Bool;

	# private attributes

	has _surface          => private 'SDL::Surface';
	has _mirrored_surface => private 'SDL::Surface';
	has _resource         => private 'Games::Neverhood::SpriteResource';

	# methods

	method BUILD {
		my $stream = SDL::RWOps->new_file($self->file, 'r') // error(SDL::get_error());
		$self->_resource(Games::Neverhood::SpriteResource->new($stream));
		$self->_surface($self->_resource->get_surface);
	}

	method x ($ ?) { $self->_resource->get_x };
	method y ($ ?) { $self->_resource->get_y };

	method surface ($ ?) {
		# TODO: mirrored_surface

		$self->_surface;
	}
}

1;
