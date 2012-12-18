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
	has is_mirrored => rw Bool, trigger => \&_mirror_set;

	# private attributes

	has _surface          => private 'SDL::Surface';
	has _mirrored_surface => private 'SDL::Surface';
	has _resource         => private 'Games::Neverhood::SpriteResource';

	# methods

	method BUILD {
		$self->_resource($;->resource_man->get_sprite($self->file));
		$self->_surface($self->_resource->get_surface);
		
		$self->x($self->_resource->get_x);
		$self->y($self->_resource->get_y);
	}

	method draw_surfaces () {
		$self->draw_surface($self->_surface);
	}
	
	method _mirror_set (Bool $mirror, Bool $old_mirror?) {
		if($mirror xor $old_mirror) { # inequivalent
			Games::Neverhood::SurfaceUtil::mirror_surface($self->_surface);
		}
	}
}

1;
