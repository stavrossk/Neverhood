# MoviePlayer - drawable object to play movies (smacker resources)
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use MooseX::Declare;

class Games::Neverhood::MoviePlayer with Games::Neverhood::Drawable {
	use SDL::Constants ':SDL::GFX';

	use constant invalidator_checks => ('x', 'y');

	# constants returned by next_frame and advance_in_time
	use constant {
		PLAYING => 1,
		LOOPED  => -1,
		ENDED   => 0,
	};

	# public attributes

	has file           => ro Str, required => 1;
	has is_double_size => ro Bool, default => 1;
	has is_loopy       => rw Bool, default => 1;

	method cur_frame   ($ ?) { $self->_resource->get_cur_frame   }
	method frame_rate  ($ ?) { $self->_resource->get_frame_rate  }
	method frame_count ($ ?) { $self->_resource->get_frame_count }

	# private attributes

	has _time_remainder      => private Num, default => 0;
	has _resource            => private 'Games::Neverhood::SmackerResource';
	has _surface             => private 'SDL::Surface';
	has _double_size_surface => private 'SDL::Surface';

	# methods

	method BUILD {
		$self->_resource($;->resource_man->get_smacker($self->file));
		$self->_surface($self->_resource->get_surface);
		$self->_double_size_surface(SDL::GFX::Rotozoom::surface($self->_surface, 0, 2, SMOOTHING_OFF));
	}

	method next_frame () {
		unless($self->_resource->next_frame()) {
			if($self->is_loopy) {
				$self->first_frame();
				return LOOPED;
			}
			return ENDED;
		}
		$self->_finish_changing_frame();
		return PLAYING;
	}

	method first_frame () {
		$self->_resource->first_frame();
		$self->_finish_changing_frame();
	}

	method _finish_changing_frame () {
		if($self->is_double_size) {
			$self->_double_size_surface(SDL::GFX::Rotozoom::surface($self->_surface, 0, 2, SMOOTHING_OFF));
			# remove the color key from it now because rotozoom makes 0,0,0 transparent for some reason
			Games::Neverhood::SurfaceUtil::set_color_keying($self->_double_size_surface, 0);
		}
		$self->invalidate();
	}

	method advance_in_time (Num $time) {
		my $return = PLAYING; # didn't invalidate

		# go to the first frame on the first update
		if($self->cur_frame == -1) {
			$return = $self->next_frame();
			$self->_time_remainder(0);
		}
		
		$time += $self->_time_remainder;
		my $frame_time = 1 / $self->frame_rate;
		if($time >= $frame_time) {
			$return = $self->next_frame();
			$time -= $frame_time;
		}
		$self->_time_remainder($time);
		return $return;
	}
	
	method draw_surfaces () {
		$self->draw_surface($self->is_double_size ? $self->_double_size_surface : $self->_surface);
	}
}

1;
