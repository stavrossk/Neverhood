# MoviePlayer - drawable object to play movies (smacker resources)
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Games::Neverhood::MoviePlayer
	with Games::Neverhood::Draw
	with Games::Neverhood::Tick
{
	use SDL::Constants ':SDL::GFX';

	ro   key            => Str, required;
	ro   is_double_size => Bool, default => 1;
	ro   palette        => Palette;
	rw   is_loopy       => Bool, default => 1;
	rpvt stopped        => Bool, default => 1;

	method cur_frame   { $self->_resource->get_cur_frame }
	method frame_count { $self->_resource->get_frame_count }

	pvt resource            => 'Games::Neverhood::SmackerResource';
	pvt surface             => Surface;
	pvt double_size_surface => Surface;

	method BUILD (@_) {
		$self->_set_resource($;->resource_man->get_smacker($self->key));
		$self->_set_surface($self->_resource->get_surface);
		$self->set_fps($self->_resource->get_frame_rate);
	}

	method next_frame () {
		unless ($self->_resource->next_frame()) {
			if ($self->is_loopy) {
				$self->_resource->stop();
				$self->_resource->next_frame();
			}
			else {
				$self->_set_stopped(1);
				return;
			}
		}

		my $surface = $self->_surface;
		if ($self->is_double_size) {
			$self->_set_double_size_surface(SDL::GFX::Rotozoom::surface($surface, 0, 2, SMOOTHING_OFF));
			$surface = $self->_double_size_surface;
			# remove the color key from it now because rotozoom makes 0,0,0 transparent for some reason
			Games::Neverhood::SurfaceUtil::set_color_keying($surface, 0);
		}
		if ($self->palette) {
			Games::Neverhood::SurfaceUtil::set_palette($surface, $self->palette);
		}
		$self->_set_stopped(0);
		$self->invalidate();
	}

	method stop () {
		$self->_resource->stop();
		$self->ticker_stop();
		$self->_set_stopped(1);
	}

	method handle_time (Num $time) {
		# go to the first frame on the first update
		if ($self->cur_frame == -1) {
			$self->next_frame();
		}
	}
	
	method handle_tick () {
		$self->next_frame();
	}

	method draw () {
		my $surface = $self->is_double_size ? $self->_double_size_surface : $self->_surface;
		$self->draw_surface($surface, $self->x, $self->y);
	}
}
