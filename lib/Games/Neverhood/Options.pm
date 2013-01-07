# Options - options object to get options
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;

class Games::Neverhood::Options {
	use Getopt::Long ();
	use File::ShareDir ();
	use Digest::SHA ();
	use SDL::Constants ':SDL::CDROM';

	rpvt_arg data_dir            => Str;
	rpvt_arg fullscreen          => Bool, default => 0;
	rpvt_arg no_frame            => Bool, default => 0;
	rpvt_arg fps_limit           => Int, default => 60;
	rpvt_arg grab_input          => Maybe(Bool);

	rpvt_arg debug               => Bool, default => 0;
	rpvt_arg mute                => Bool, default => 0;
	rpvt_arg starting_scene      => SceneName, default => 'Nursery::One';
	rpvt_arg starting_prev_scene => Maybe(SceneName);
	rpvt_arg write_checksums     => Bool, default => 0;
	rpvt     share_dir           => Str;

	method BUILD (@_) {
		$self->_set_grab_input($self->no_frame || $self->fullscreen) unless defined $self->grab_input;
		$self->_set_starting_prev_scene($self->starting_scene) unless defined $self->starting_prev_scene;
		$self->_set_share_dir(File::ShareDir::dist_dir('Games-Neverhood'));

		# for access from XS
		*Debug = \$self->debug;
	}

	method new_with_options ($class:) {
		my (%o, $config, $write_checksums);
		my @saved_options   = qw/data_dir fullscreen no_frame fps_limit grab_input/;
		my @unsaved_options = qw/debug mute starting_scene starting_prev_scene/;

		Getopt::Long::GetOptions(
			'data-dir=s'    => \$o{data_dir},
			'cd'            => sub { $o{data_dir} = "" },
			'fullscreen'    => \$o{fullscreen},
			'window'        => sub { $o{fullscreen} = 0; $o{no_frame} = 1 },
			'normal-window' => sub { $o{fullscreen} = 0; $o{no_frame} = 0 },
			'fps-limit=i'   => \$o{fps_limit},
			'grab-input'    => \$o{grab_input},

			'config'                  => \$config,
			'debug|d'                 => \$o{debug},
			'mute'                    => \$o{mute},
			'starting-scene|s=s'      => \$o{starting_scene},
			'starting-prev-scene|p=s' => \$o{starting_prev_scene},
			'write-checksums'         => \$write_checksums,
			'help|h|?'                => sub { $class->_print_usage() },
		) or $class->_print_usage(exitval => 1);
		
		my $options = $class->new(
			map maybe($_, $o{$_}), @saved_options, @unsaved_options,
		);
		
		my $share_dir = $options->share_dir;
		my $config_file = cat_file($share_dir, 'config.yaml');

		my $saved_options;
		eval { $saved_options = retrieve($config_file) };
		if ($saved_options and ref $saved_options eq 'HASH') {
			for (@saved_options) {
				$o{$_} = $saved_options->{$_} if !defined $o{$_} and defined $saved_options->{$_};
			}
		}

		say '';
		$config = $config || !$saved_options;
		my $data_dir = $o{data_dir};
		if ($config or !defined $data_dir) {
			say("Gonna config");
			say("DATA dirs are where all dem blb files are hidden");
		}
		
		my $valid_data_dir;
		{
			if (defined $data_dir) {
				if ($data_dir eq "") { # check CD drives for data dir
					SDLx::App->init(['cdrom']);
					for my $drive (0..SDL::CDROM::num_drives()-1) {
						my $cd = SDL::CD->new($drive);
						if ($cd and $cd->status > CD_TRAYEMPTY) {
							my $data_dir = cat_dir(SDL::CDROM::name($drive), 'DATA');
							if ($class->_is_valid_data_dir($data_dir, $share_dir, $write_checksums)) {
								$valid_data_dir = $data_dir;
								last;
							}
						}
					}
					unless (defined $valid_data_dir) {
						say("No valid CD could be found. You may just need to enter the full path to the CDs DATA dir");
					}
				}
				else { # check string for being data dir
					if ($class->_is_valid_data_dir($data_dir, $share_dir, $write_checksums)) {
						$valid_data_dir = $data_dir;
					}
					else {
						say("Data dir '".$data_dir."' not valid. Data dir must contain the 7 blb files")
					}
				}
				
			}

			unless (defined $valid_data_dir) {
				say("Enter the path to DATA dir or an empty line to search inserted CDs");
				chomp($data_dir = <STDIN> // "");
				say '';
				redo;
			}
		}
		
		$options->_set_data_dir($data_dir);
		# TODO: more config stuff here
		
		store($config_file, { map {$_ => $options->$_} @saved_options });
		
		$options->_set_data_dir($valid_data_dir);
		$options->_set_share_dir($share_dir);

		return $options;
	}

	method _print_usage ($self: Int :$verbose=1, Int :$exitval=0) {
		require Pod::Usage;
		require Pod::Find;
		Pod::Usage::pod2usage(
			-input => Pod::Find::pod_where({-inc => 1}, __PACKAGE__),
			-verbose => $verbose,
			-exitval => $exitval,
		);
	}
	
	method _is_valid_data_dir ($self: Str $data_dir, Str $share_dir, Bool $write_checksums) {
		-d $data_dir or return 0;
		
		my $valid = 1;
		my @files =  qw/a c hd i m s t/;
		for (@files) {
			my $file = cat_file($data_dir, "$_.blb");
			if (-s $file <= 0) {
				$valid = 0;
				last;
			}
		}
		
		my $checksums_passed = 1;
		my $checksums = eval { retrieve(cat_file($share_dir, 'checksums.yaml')) };
		unless (defined $checksums) {
			$write_checksums = 1;
			$checksums = {};
		}
		
		for (@files) {
			my $file = cat_file($data_dir, "$_.blb");
			unless (open FILE, "<", $file) {
				say STDERR "Couldn't open $file for testing checksum: $!";
				$checksums_passed = 0;
				next;
			}
			
			my $data;
			binmode FILE;
			# Generating these checksums takes too long, so we're only checking the start of each file
			unless (defined read FILE, $data, 4096) {
				say STDERR "Couldn't read from $file for testing checksum: $!";
				$checksums_passed = 0;
				next;
			}
			
			my $digest = Digest::SHA::sha256_base64($data);
			if ($write_checksums) {
				$checksums->{$_} = $digest;
			}
			elsif (!defined $checksums->{$_} or $digest ne $checksums->{$_}) {
				say STDERR "Checksum on $file failed";
				$checksums_passed = 0;
			}
		}
		unless ($checksums_passed) {
			say STDERR "Checksums failed. Gonna continue anyway, but it doesn't look good";
		}
		
		if ($write_checksums) {
			eval { store("checksums.yaml", $checksums); 1 } and say "Checksums saved to current directory";
		}
		
		return $valid;
	}
}

1;

__END__

=head1 SYNOPSIS

nhc [-?dhps] [long options]

=head1 Options

 --data-dir=DIR     Set the data dir (BLB files)
 --cd               Search for the data dir on your CDs
 --fullscreen       Run the game fullscreen
 --window           Run the game in a frame-less window (default)
 --normal-window    Run the game in a normal window
 --fps-limit=FPS    Set the FPS limit; 0 for no limit (default=60)
 --grab-input       Confine the mouse to the window (default)

 -d --debug         Enable all debugging features
 --mute             Mute all music and sound
 -s --starting-scene=SCENE
                    Set the starting scene (default=Nursery::One)
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
