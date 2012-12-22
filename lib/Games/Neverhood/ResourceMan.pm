# Games::Neverhood::ResourceMan - manages loading and unloading of resources from archives
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;

class Games::Neverhood::ResourceMan {
	has _entries   => private HashRef;
	has _resources => private HashRef;

	method BUILD (@_) {
		chop(my $prefix = data_file("a")); # to get a dir separator at the end we have to put in a filename then chop it off
		Games::Neverhood::ResourceEntry::load_archives($prefix, $self->_entries);
	}
	
	method _get_resource (Str $key, Str $class) {
		$key =~ /^[A-F0-9]{8}$/ or error("Key invalid: '$key'");
		
		my $entry = $self->_entries->{$key};
		while ($entry and $entry->get_compr_type == 0x65) {
			$key = sprintf("%08X", $entry->get_disk_size);
			$entry = $self->_entries->{$key};
		}
		
		my $resource;
		unless ($resource = $self->_resources->{$key}) {
			$class = "Games::Neverhood::${class}Resource";
			$resource = $class->new($entry);
			
			weaken($self->_resources->{$key} = $resource);
		}
		
		return $resource;
	}
	
	method clean_destroyed_resources () {
		while (my ($key, $value) = each %{$self->_resources}) {
			delete $self->_resources->{$key} unless defined $value;
		}
	}
	
	method get_sprite   (Str $key) { $self->_get_resource($key, 'Sprite'  ) }
	method get_palette  (Str $key) { $self->_get_resource($key, 'Palette' ) }
	method get_sequence (Str $key) { $self->_get_resource($key, 'Sequence') }
	method get_sound    (Str $key) { $self->_get_resource($key, 'Sound'   ) }
	method get_music    (Str $key) { $self->_get_resource($key, 'Music'   ) }
	method get_smacker  (Str $key) { $self->_get_resource($key, 'Smacker' ) }
}

1;
