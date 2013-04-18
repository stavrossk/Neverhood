=head1 NAME

Neverhood::ResourceMan - manages loading and unloading of resources from archives

=cut

class Neverhood::ResourceMan {
	pvt entries   => HashRef;
	pvt resources => HashRef;

	method BUILD (@_) {
		# to get a dir separator at the end we have to put in a filename then chop it off
		my $prefix = catfile($;->data_dir, "a");
		chop $prefix;
		Neverhood::ResourceEntry::load_archives($prefix, $self->_entries);
	}

	method _get_entry (ResourceKey $key) {
		my $entry = $self->_entries->{$key};
		while ($entry and $entry->get_compr_type == 0x65) {
			$key = sprintf("%08X", $entry->get_disk_size);
			$entry = $self->_entries->{$key};
		}
		return $entry;
	}

	method _get_resource (ResourceKey $key, Neverhood::ResourceEntry $entry) {
		my $resource;
		unless ($resource = $self->_resources->{$key}) {
			my $class = do { given ($entry->get_type) {
				when (2)  { 'Sprite' }
				when (3)  { 'Palette' }
				when (4)  { 'Sequence' }
				when (7)  { 'Sound' }
				when (8)  { 'Music' }
				when (10) { 'Smacker' }
			}};
			$class = "Neverhood::${class}Resource";
			$resource = $class->new($entry);

			weaken($self->_resources->{$key} = $resource);
		}
		return $resource;
	}

	method _get_resource_of_type (ResourceKey $key, Int $type) {
		my $entry = $self->_get_entry($key);
		$entry or error("Key %08X is not in entry hash", $key);
		$entry->get_type == $type or error("Trying to load type %d as type %d", $entry->get_type, $type);
		return $self->_get_resource($key, $entry);
	}

	method clean_destroyed_resources () {
		while (my ($key, $value) = each %{$self->_resources}) {
			delete $self->_resources->{$key} if !defined $value;
		}
	}

	method get_sprite   (ResourceKey $key) { $self->_get_resource_of_type($key, 2) }
	method get_sequence (ResourceKey $key) { $self->_get_resource_of_type($key, 4) }
	method get_sound    (ResourceKey $key) { $self->_get_resource_of_type($key, 7) }
	method get_music    (ResourceKey $key) { $self->_get_resource_of_type($key, 8) }
	method get_smacker  (ResourceKey $key) { $self->_get_resource_of_type($key, 10) }

	method get_palette (ResourceKey $key) {
		my $entry = $self->_get_entry($key);
		$entry or error("Key %08X is not in entry hash", $key);
		return $self->_get_resource($key, $entry) if $entry->get_type == 3;
		return $self->_get_resource($key, $entry)->get_palette if $entry->get_type == 2 || $entry->get_type == 4;
		error("Trying to load type %d as type 2/3/4", $entry->get_type);
	}
}
