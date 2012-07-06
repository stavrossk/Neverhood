# Options - command line options with MooseX::Getopt
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use MooseX::Declare;

class Games::Neverhood::Options {
	use Getopt::Long::Descriptive ();
	use File::Spec ();
	use File::ShareDir ();
	use Games::Neverhood;

	has data_dir            => init_private_set Str, default => sub { File::Spec->catdir('DATA') };
	has share_dir           => init_private_set Str, default => sub { File::ShareDir::dist_dir('Games-Neverhood') };
	has fullscreen          => init_private_set Bool, default => 0;
	has no_frame            => init_private_set Bool, default => 0;
	has fps_limit           => init_private_set Int, default => 60;
	has grab_input          => init_private_set Maybe(Bool);
	has debug               => init_private_set Bool, default => 0;
	has starting_scene      => init_private_set SceneName, default => 'TP::Nursery::One';
	has starting_prev_scene => init_private_set Maybe(SceneName);

	method BUILD {
		$self->grab_input($self->no_frame || $self->fullscreen) unless defined $self->grab_input;
		$self->starting_prev_scene($self->starting_scene) unless defined $self->starting_prev_scene;
		
		# for access from XS
		*Debug = \$self->debug;
	}

	method new_with_options (ClassName $class:) {
		my ($starting_scene, $starting_prev_scene);

		my ($opt, $usage) = Getopt::Long::Descriptive::describe_options(
			'nhc %o',
			['data-dir=s'    => "Set the dir for the game's assets (default=./DATA)"],
			['share-dir=s'   => "Set the dir for the game's savedata"],
			['fullscreen'    => "Run the game fullscreen"],
			['window'        => "Run the game in a frame-less window (default)", {implies => {fullscreen => 0, window => 1}}],
			['normal-window' => "Run the game in a normal window", {implies => {fullscreen => 0, window => 0}}],
			['fps-limit=i'   => "Set the fps limit; 0 for no limit (default=60)"],
			['grab-input'    => "Confine the mouse to the window (default)"],
			[],
			['debug|d'                 => "Enable all debugging features"],
			['starting-scene|s=s'      => "Set the starting scene (default=TP::Nursery::One)"],
			['starting-prev-scene|p=s' => "Set the starting prev scene (default=starting-scene)"],
			['help|h|?'                => "Show this help"],
		);

		if($opt->help) {
			say $usage->text;
			exit;
		}

		my $options = $class->new(
			maybe(data_dir            => $opt->data_dir),
			maybe(share_dir           => $opt->share_dir),
			maybe(fullscreen          => $opt->fullscreen),
			maybe(no_frame            => $opt->window),
			maybe(fps_limit           => $opt->fps_limit),
			maybe(grab_input          => $opt->grab_input),
			maybe(debug               => $opt->debug),
			maybe(starting_scene      => $opt->starting_scene),
			maybe(starting_prev_scene => $opt->starting_prev_scene),
		);

		return $options;
	}
}

1;
