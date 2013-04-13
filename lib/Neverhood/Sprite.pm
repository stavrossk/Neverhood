=head1 NAME

Neverhood::Sprite - drawable single image sprites

=cut

class Neverhood::Sprite with Neverhood::Draw {
	ro key       => ResourceKey, required;
	rw palette   => Maybe[Palette], trigger, check;
	rw mirror    => Bool, trigger, check;
	pvt surface  => Surface;
	pvt resource => 'Neverhood::SpriteResource';

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
			Neverhood::SurfaceUtil::mirror_surface($self->_surface);
		}
	}

	method _palette_trigger (Maybe[Palette] $palette, $o?) {
		Neverhood::SurfaceUtil::set_palette($self->_surface, $palette);
		Neverhood::SurfaceUtil::set_color_keying($self->_surface, 1);
	}

	method reset_palette {
		$self->set_palette($self->_resource->get_palette);
	}
}
