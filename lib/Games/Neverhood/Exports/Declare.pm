# Games::Neverhood::Exports::Declare
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use strict;
use warnings;

package Games::Neverhood::Exports::Declare;
use base 'Devel::Declare::Context::Simple';
use Carp 'croak';
our @CARP_NOT = qw( Devel::Declare );

sub import {
	shift->import_to(scalar caller);
}

sub import_to {
	my ($class, $caller) = @_;
	my $ctx = __PACKAGE__->new;

	Devel::Declare->setup_for(
		$caller,
		{
			x => { const => sub { $ctx->resource_key_parser(@_) } },
		},
	);

	no strict 'refs';
	*{$caller.'::x'} = sub ($) { Games::Neverhood::ResourceKey->new(@_) };
}

sub resource_key_parser {
	# parses things like
	# x  *  1234ABCD
	# into
	# x '1234ABCD'
	
	my $self = shift;
	$self->init(@_);

	my $line = $self->get_linestr;
	$self->skip_declarator;
	my $start_pos = $self->offset;
	$self->skipspace;
	
	my $pos = $self->offset;
	substr($line, $pos, 1) eq '*' or croak "Expected * after x";
	$self->inc_offset(1);
	$self->skipspace;
	
	$pos = $self->offset;
	my $len = Devel::Declare::toke_scan_word($self->offset, 0) // 0;
	$len or croak "Expected token after x*";
	my $key = substr($line, $pos, $len);
	$key =~ /^[0-9A-F]{8}$/ or croak "ResourceKey invalid: '$key'";
	$pos += $len;
	
	substr($line, $start_pos, $pos - $start_pos) = " '$key'";
	$self->set_linestr($line);

	return;
}

1;
