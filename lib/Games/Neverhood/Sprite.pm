# Sprite - drawable single image sprites
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Games::Neverhood::Sprite with Games::Neverhood::Draw {
	ro key       => ResourceKey, required;
	rw palette   => Maybe[Palette], trigger, check;
	rw mirror    => Bool, trigger, check;
	pvt surface  => Surface;
	pvt resource => 'Games::Neverhood::SpriteResource';

	method BUILD (@_) {
		$self->_set_resource($;->resource_man->get_sprite($self->key));
		$self->_set_surface($self->_resource->get_surface);
		$self->set_palette($self->_resource->get_palette) if !$self->palette;

		$self->set_x($self->_resource->get_x) if !defined $self->x;
		$self->set_y($self->_resource->get_y) if !defined $self->y;
	}

	method handle_tick () {

	}

	method draw {
		$self->draw_surface($self->_surface, $self->x, $self->y);
	}

	method _mirror_trigger (Bool $mirror, Bool $old_mirror?) {
		if ($mirror xor $old_mirror) { # inequivalent
			Games::Neverhood::SurfaceUtil::mirror_surface($self->_surface);
		}
	}

	method _palette_trigger (Maybe[Palette] $palette, $o?) {
		Games::Neverhood::SurfaceUtil::set_palette($self->_surface, $palette);
		Games::Neverhood::SurfaceUtil::set_color_keying($self->_surface, 1);
	}

	method reset_palette {
		$self->set_palette($self->_resource->get_palette);
	}
}
