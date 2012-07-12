# Options - options object to get options
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use MooseX::Declare;

class Games::Neverhood::Options {
	use Getopt::Long ();
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
		my ($data_dir, $share_dir, $fullscreen, $no_frame, $fps_limit, $grab_input);
		my ($debug, $starting_scene, $starting_prev_scene);

		Getopt::Long::GetOptions(
			'data-dir=s'    => \$data_dir,
			'share-dir=s'   => \$share_dir,
			'fullscreen'    => \$fullscreen,
			'window'        => sub { $fullscreen = 0; $no_frame = 1 },
			'normal-window' => sub { $fullscreen = 0; $no_frame = 0 },
			'fps-limit=i'   => \$fps_limit,
			'grab-input'    => \$grab_input,

			'debug|d'                 => \$debug,
			'starting-scene|s=s'      => \$starting_scene,
			'starting-prev-scene|p=s' => \$starting_prev_scene,
			'help|h|?'                => sub { $class->print_usage() },
		) or $class->print_usage(exitval => 1);

		my $options = $class->new(
			maybe(data_dir            => $data_dir),
			maybe(share_dir           => $share_dir),
			maybe(fullscreen          => $fullscreen),
			maybe(no_frame            => $no_frame),
			maybe(fps_limit           => $fps_limit),
			maybe(grab_input          => $grab_input),
			maybe(debug               => $debug),
			maybe(starting_scene      => $starting_scene),
			maybe(starting_prev_scene => $starting_prev_scene),
		);

		return $options;
	}
	
	method print_usage ($self: Int :$verbose=1, Int :$exitval=0) {
		require Pod::Usage;
		require Pod::Find;
		Pod::Usage::pod2usage(
			-input => Pod::Find::pod_where({-inc => 1}, __PACKAGE__),
			-verbose => $verbose,
			-exitval => $exitval,
		);
	}
}

1;

__END__

=head1 SYNOPSIS

nhc [-?dhps] [long options]

=head1 Options

 --data-dir=DIR     Set the data dir with the Blb files (default=./DATA)
 --share-dir=DIR    Set the game's share dir
 --fullscreen       Run the game fullscreen
 --window           Run the game in a frame-less window (default)
 --normal-window    Run the game in a normal window
 --fps-limit=FPS    Set the FPS limit; 0 for no limit (default=60)
 --grab-input       Confine the mouse to the window (default)

 -d --debug         Enable all debugging features
 -s --starting-scene=SCENE
                    Set the starting scene (default=TP::Nursery::1)
 --starting-prev-scene=SCENE
                    Set the starting prev scene (default=starting-scene)
 -? -h --help       Show this help

=head1 In-game

Press Alt-F4 at any time to quit.

=head1 Cheats

 FASTFORWARD             Toggle fast sprite animation
 SCREENSNAPSHOT          Save a screenshot to <cwd>/NevShot.bmp
 HAPPYBIRTHDAYKLAYMEN    Skip the Nursery (the first room)
 LETMEOUTOFHERE          Skip the Nursery Lobby (the second room)
 PLEASE                  Solve the puzzle in the Dynamite Shack
