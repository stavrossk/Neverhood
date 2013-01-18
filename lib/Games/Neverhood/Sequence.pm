# Sequence - drawable sequence of surfaces
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Games::Neverhood::Sequence
	with Games::Neverhood::Draw
{
	ro key            => Str, required;
	rw mirror         => Bool, trigger;
	rw play_backwards => Bool;

	pvt resource    => 'Games::Neverhood::SequenceResource';
	
	rpvt frame_index => Int;
	rpvt frame_count => Int;
	
	# frame
	pvt surface                 => Surface;
	pvt frame_ticks             => Int;
	pvt draw_offset_x           => Int;
	pvt draw_offset_y           => Int;
	pvt delta_x                 => Int;
	pvt delta_y                 => Int;
	pvt collision_bounds_offset => Int;

	method BUILD (@_) {
		$self->_set_resource($;->resource_man->get_sequence($self->key));
		
		$self->_frame_count($self->_resource->get_frame_count);
		unless (defined $self->cur_frame_index) {
			$self->_set_cur_frame_index($self->play_backwards ? $self->frame_count : -1);
		}
	}
	
	method next_frame_index {
		my $frame = $self->frame_index;
		if ($self->play_backwards) {
			
		}
		else {
		
		}
	
		$self->_set_surface($self->_resource->get_frame_surface());
		$self->set_palette($self->_resource->get_palette);
		
		$self->set_x($self->_resource->get_x) unless defined $self->x;
		$self->set_y($self->_resource->get_y) unless defined $self->y;
	}
	
	method handle_tick () {
	
	}

	method draw () {
		$self->draw_surface($self->_surface, $self->x, $self->y);
	}
	
	method _mirror_trigger (Bool $mirror, Bool $old_mirror) {
		if($mirror xor $old_mirror) { # inequivalent
			Games::Neverhood::SurfaceUtil::mirror_surface($self->_surface);
		}
	}
	

}
