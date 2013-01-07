# Scene::Test
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;

class Games::Neverhood::Scene::Test extends Games::Neverhood::Scene {
	method setup (SceneName $prev_scene) {
		# $self->set_movie('40800711');
		# $self->set_movie('21080011');
		
		my $movie = Mov->new(key => '21080011');
		$self->set_movie($movie);
	}
}

class Mov extends Games::Neverhood::MoviePlayer {
	after handle_tick () {
		if ($self->cur_frame == 33) { $self->stop; $;->scene->_order->remove($self); $;->scene->_set_movie(undef) }
	}
}

1;
