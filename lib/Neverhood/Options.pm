=head1 NAME

Neverhood::Options - options object to get and pass options

=cut

class Neverhood::Options {
	use Getopt::Long ();
	use File::ShareDir ();
	use Digest::SHA ();
	use SDL::Constants ':SDL::CDROM';
	use YAML::XS;
	use subs qw/store retrieve/;

	rw data_dir   => Str;
	rw fullscreen => Bool;
	rw no_frame   => Bool;
	rw fps_limit  => Int;
	rw grab_input => Bool;

	rw debug          => Bool;
	rw mute           => Bool;
	rw starting_scene => SceneName;
	rw starting_which => Str;
	rw_ share_dir     => Str;

	method BUILD {
		$self->set_grab_input($self->no_frame || $self->fullscreen) if !defined $self->grab_input;
		$self->set_share_dir(File::ShareDir::dist_dir('Neverhood'));
	}

	method new_with_opts ($class:) {
		my (%o, $config, $write_checksums);
		my @saved_options   = qw/data_dir fullscreen no_frame fps_limit grab_input/;
		my @unsaved_options = qw/debug mute starting_scene starting_which/;

		Getopt::Long::Configure("bundling");
		Getopt::Long::GetOptions(
			'data-dir=s'    => \$o{data_dir},
			'cdrom'         => sub { $o{data_dir} = "" },
			'fullscreen'    => \$o{fullscreen},
			'window'        => sub { $o{fullscreen} = 0; $o{no_frame} = 1 },
			'normal-window' => sub { $o{fullscreen} = 0; $o{no_frame} = 0 },
			'fps-limit=i'   => \$o{fps_limit},
			'grab-input'    => \$o{grab_input},

			'config'             => \$config,
			'debug|d'            => \$o{debug},
			'mute'               => \$o{mute},
			'starting-scene|s=s' => \$o{starting_scene},
			'starting-which|w=s' => \$o{starting_which},
			'write-checksums'    => \$write_checksums,
			'help|h|?'           => sub { _exit_with_usage() },
		) or _exit_with_usage(exitval => 1);

		my $options = $class->new(
			map maybe($_, $o{$_}), @saved_options, @unsaved_options,
		);

		my $share_dir = $options->share_dir;
		my $config_file = catfile($share_dir, 'config.yaml');

		my $saved_options;
		eval { $saved_options = retrieve($config_file) };
		if ($saved_options and ref $saved_options eq 'HASH') {
			for (@saved_options) {
				$o{$_} = $saved_options->{$_} if !defined $o{$_};
			}
		}
		else {
			undef $saved_options;
		}

		say '';
		$config = $config || !$saved_options;
		my $data_dir = $o{data_dir};
		if ($config or !defined $data_dir) {
			say "Gonna config";
			say "DATA dirs are where all dem blb files are hidden";
		}

		my $valid_data_dir;
		{
			if (defined $data_dir) {
				if ($data_dir eq "") { # check CD drives for data dir
					SDLx::App->init(['cdrom']);
					for my $drive (0..SDL::CDROM::num_drives()-1) {
						my $cd = SDL::CD->new($drive);
						if ($cd and $cd->status > CD_TRAYEMPTY) {
							my $data_dir = catdir(SDL::CDROM::name($drive), 'DATA');
							if (_is_valid_data_dir($data_dir, $share_dir, $write_checksums)) {
								$valid_data_dir = $data_dir;
								last;
							}
						}
					}
					if (!defined $valid_data_dir) {
						say "No valid CD could be found. You may just need to enter the full path to the CDs DATA dir";
					}
				}
				else { # check string for being data dir
					if (_is_valid_data_dir($data_dir, $share_dir, $write_checksums)) {
						$valid_data_dir = $data_dir;
					}
					else {
						say "Data dir '$data_dir' not valid. Data dir must contain the 7 blb files";
					}
				}

			}

			if (!defined $valid_data_dir) {
				say("Enter the path to DATA dir or an empty line to search inserted CDs");
				chomp($data_dir = <STDIN> // "");
				say '';
				redo;
			}
		}

		$options->set_data_dir($data_dir);
		# TODO: more config stuff here

		store($config_file, { map maybe($_ => $options->$_), @saved_options });

		$options->set_data_dir($valid_data_dir);

		return $options;
	}

	func _exit_with_usage (Int :$verbose=1, Int :$exitval=0) {
		require Pod::Usage;
		require Pod::Find;
		Pod::Usage::pod2usage(
			-input => Pod::Find::pod_where({-inc => 1}, __PACKAGE__),
			-verbose => $verbose,
			-exitval => $exitval,
		);
	}

	func _is_valid_data_dir (Str $data_dir, Str $share_dir, Bool $write_checksums) {
		-d $data_dir or return 0;

		my $valid = 1;
		my @files =  qw/a c hd i m s t/;
		for (@files) {
			my $file = catfile($data_dir, "$_.blb");
			if (-s $file <= 0) {
				$valid = 0;
				last;
			}
		}

		my $checksums_passed = 1;
		my $checksums = eval { retrieve(catfile($share_dir, 'checksums.yaml')) };
		if (!defined $checksums) {
			$write_checksums = 1;
			$checksums = {};
		}

		for (@files) {
			my $filename = catfile($data_dir, "$_.blb");
			my $file;
			if (!open $file, "<", $filename) {
				say STDERR "Couldn't open $filename for testing checksum: $!";
				$checksums_passed = 0;
				next;
			}

			my $data;
			binmode $file;
			# Generating these checksums takes too long, so we're only checking the start of each file
			if (!defined read $file, $data, 4096) {
				say STDERR "Couldn't read from $file for testing checksum: $!";
				$checksums_passed = 0;
				close $file;
				next;
			}
			close $file;

			my $digest = Digest::SHA::sha256_base64($data);
			if ($write_checksums) {
				$checksums->{$_} = $digest;
			}
			elsif (!defined $checksums->{$_} or $digest ne $checksums->{$_}) {
				say STDERR "Checksum on $file failed";
				$checksums_passed = 0;
			}
		}
		if (!$checksums_passed) {
			say STDERR "Gonna continue anyway, but it's not looking good";
		}

		if ($write_checksums) {
			eval { store("checksums.yaml", $checksums); 1 } and say "Checksums saved to current directory";
		}

		return $valid;
	}
	
	# user-readable serialization
	BEGIN {
		*store    = \&YAML::XS::DumpFile;
		*retrieve = \&YAML::XS::LoadFile;
	}
}

__END__

=head1 SYNOPSIS

nhc [-?dhps] [long options]

=head1 Options

 --data-dir=DIR     Set the data dir (BLB files)
 --cdrom            Search for the data dir on your CD drives
 --fullscreen       Run the game fullscreen
 --window           Run the game in a frame-less window (default)
 --normal-window    Run the game in a normal window
 --fps-limit=FPS    Set the FPS limit; 0 for no limit (default=60)
 --grab-input       Confine the mouse to the window (default)

 -d --debug         Enable all debugging features
 --mute             Mute all music and sound
 -s --starting-scene=SCENE
                    Set the starting scene (default=Nursery::One)
 -p --starting-which=WHICH
                    Set which entrance to use (default="")
 -? -h --help       Show this help

=head1 In-game

Press Alt-F4 at any time to quit.

=head1 Cheats

 FASTFORWARD             Toggle fast sprite animation
 SCREENSNAPSHOT          Save a screenshot to <cwd>/NevShot.bmp
 HAPPYBIRTHDAYKLAYMEN    Skip the Nursery (the first room)
 LETMEOUTOFHERE          Skip the Nursery Lobby (the second room)
 PLEASE                  Solve the puzzle in the Dynamite Shack
