# Games::Neverhood::Util::Declare
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use strict;
use warnings;

package Games::Neverhood::Util::Declare;
use base 'Devel::Declare::Context::Simple';
use Carp 'croak';
our @CARP_NOT = qw/Devel::Declare/;
use B::Hooks::EndOfScope;

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
			
			before => { const => sub { $ctx->method_modifier_parser(@_) } },
			after  => { const => sub { $ctx->method_modifier_parser(@_) } },
			around => { const => sub { $ctx->method_modifier_parser(@_) } },
			
			class => { const => sub { $ctx->class_or_role_parser(@_) } },
			role  => { const => sub { $ctx->class_or_role_parser(@_) } },
		},
	);

	no strict 'refs';
	*{$caller.'::x'} = sub ($) { Games::Neverhood::ResourceKey->new(@_) };
	*{$caller.'::class'} = sub () {};
	*{$caller.'::role'} = sub () {};
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
	my $len = Devel::Declare::toke_scan_word($self->offset, 0);
	$len or croak "Expected word after x*";
	my $key = substr($line, $pos, $len);
	$key =~ /^[0-9A-F]{8}$/ or croak "ResourceKey invalid: '$key'";
	$pos += $len;
	
	substr($line, $start_pos, $pos - $start_pos) = " '$key'";
	$self->set_linestr($line);

	return;
}

sub method_modifier_parser {
	# parses
	# around foo ($this: $foo, $bar) { ... }
	# into
	# around 'foo', func ($orig, $this, $foo, $bar) { shift; shift; ... };
	
	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;
	
	my $line = $self->get_linestr;
	$self->skip_declarator;
	$self->skipspace;
	my $start_pos = $self->offset;
	
	my $pos = $self->offset;
	my $len = Devel::Declare::toke_scan_word($self->offset, 0);
	$len or croak "Expected word after $declarator";
	my $method = substr($line, $pos, $len);
	
	$self->inc_offset($len);
	$self->skipspace;
	my $proto = $self->strip_proto // '';
	$self->skipspace;
	$line = $self->get_linestr;
	$pos = $self->offset;
	substr($line, $pos++, 1) eq '{' or croak "Illegal $declarator definition";
	
	my $insert = '';
	if ($declarator eq "around") {
		$proto =~ s/^\s*(\$\w+):\s*//;
		my $invocant = defined $1 ? $1 : '$self';
		$proto = "\$orig, $invocant, $proto";
		
		$insert .= "'$method', func ($proto) { shift; shift; ";
	}
	else {
		$insert .= "'$method', method ($proto) { ";
	}
	$insert .= "BEGIN { Games::Neverhood::Util::Declare::on_method_modifier_end() } ";
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);
	
	chomp $line;
	say $line;
	
	return;
}

sub on_method_modifier_end {
	on_scope_end {
		my $line = Devel::Declare::get_linestr;
		my $pos = Devel::Declare::get_linestr_offset;
		substr($line, $pos, 0) = ';';
		Devel::Declare::set_linestr($line);
	}
}

sub class_or_role_parser {
	# parses
	# role Foo::Bar {
		# ...
	# }
	# into
	# role; {
		# package Foo::Bar;
		# use Mouse::Role;
		# use Games::Neverhood::Util -role;
		# ...
	# }
	# {
		# package Foo::Bar;
		# __PACKAGE__->meta->make_immutable;
		# our @requires;
		# Mouse::Role::requires(@requires);
		# undef @requires;
	# }
	
	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;
	my $is_role = $declarator eq 'role';
	
	my $line = $self->get_linestr;
	$self->skip_declarator;
	my $start_pos = $self->offset;
	$self->skipspace;
	
	my $pos = $self->offset;
	my $len = Devel::Declare::toke_scan_word($self->offset, 0);
	# $len or croak "Expected word after $declarator";
	my $package = substr($line, $pos, $len);
	
	$self->inc_offset($len);
	$self->skipspace;
	$pos = $self->offset;
	substr($line, $pos++, 1) eq '{' or croak "Illegal $declarator definition";
	
	my $insert = sprintf '; { package %s; use %s; use Games::Neverhood::Util::Declare; use Method::Signatures; ',
		$package, $is_role ? "Mouse::Role" : "Mouse", $is_role ? "role" : "class";
	$insert .= sprintf 'my $__SCOPE__; {$__SCOPE__ = bless \(my $t = "%s"), "%s"} ',
		$package, $is_role ? "Games::Neverhood::Util::OnEndRole" : "Games::Neverhood::Util::OnEndClass";
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);
	
	chomp $line;
	say $line;
	
	return;
}

sub on_class_or_role_end {
	my ($package, $is_role) = @_;
	on_scope_end {
		my $line = Devel::Declare::get_linestr;
		my $pos = Devel::Declare::get_linestr_offset;
		my $insert =  "{ $package->meta->make_immutable; ";
		if ($is_role) {
			$insert .= "package $package; our @requires; Mouse::Role::requires(@requires); undef @requires; "
		}
		$insert .= "} ";
		substr($line, $pos, 0) = $insert;
		Devel::Declare::set_linestr($line);
	}
}

sub on_end_role {
	on_scope_end {
		my $class = ${+shift};
		$class->meta->make_immutable;
		no strict 'refs';
		my $requires = $class."::requires";
		Mouse::Role::requires(@$requires); undef @$requires;
	}
}

1;
