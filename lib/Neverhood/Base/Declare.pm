use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare;
use base 'Devel::Declare::Context::Simple', 'Method::Signatures';
use Carp qw/croak/;
our @CARP_NOT = 'Devel::Declare';
use B::Hooks::EndOfScope;
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [
		qw/ x func method _around trigger build class role with /,
	],
);

sub x ($) { Neverhood::ResourceKey->new(@_) }
sub func    (&) {}
sub method  (&) {}
sub _around (&) {}
sub trigger (;$) { _trigger => @_ ? $_[0] : scalar caller }
sub build   (;$) { builder => 1 }
sub class () {}
sub role  () {}

sub setup_declarators {
	my ($class, $caller) = @_;
	$caller //= scalar caller;
	my $ctx = $class->new;
	my $warnings = warnings::enabled("redefine");

	my $signature = sub {
		my $name = shift;
		my $ctx = $class->new(
			into => $caller,
			name => $name,
			@_,
		);

		return $name => { const => sub { $ctx->parser(@_, $warnings) } };
	};

	Devel::Declare->setup_for(
		$caller,
		{
			x => { const => sub { $ctx->resource_key_parser(@_) } },

			$signature->( func    => () ),
			$signature->( method  => ( invocant => '$self' ) ),
			$signature->( _around => ( invocant => '$self', pre_invocant => '$orig' ) ),
			before => { const => sub { $ctx->method_modifier_parser(@_) } },
			after  => { const => sub { $ctx->method_modifier_parser(@_) } },
			around => { const => sub { $ctx->method_modifier_parser(@_) } },
			
			trigger => { const => sub { $ctx->trigger_or_builder_parser(@_) } },
			build   => { const => sub { $ctx->trigger_or_builder_parser(@_) } },

			class => { const => sub { $ctx->class_or_role_parser(@_) } },
			role  => { const => sub { $ctx->class_or_role_parser(@_) } },
		},
	);
}

sub teardown_declarators {
	my ($class, $caller) = @_;
	$caller //= scalar caller;
	Devel::Declare->teardown_for($caller);
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
	# before foo ($this: $foo, $bar) { ... }
	# into
	# before 'foo', method ($this: $foo, $bar) { ... };

	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;

	my $line = $self->get_linestr;
	$self->skip_declarator;
	$self->skipspace;
	my $start_pos = $self->offset;

	my $pos = $self->offset;
	my $len = Devel::Declare::toke_scan_word($self->offset, 0);
	return if !$len; # we shouldn't be processing this; let Mouse::before etc. process it
	my $method = substr($line, $pos, $len);

	$self->inc_offset($len);
	$self->skipspace;
	my $proto = $self->strip_proto // '@_';
	$self->skipspace;
	$line = $self->get_linestr;
	$pos = $self->offset;
	substr($line, $pos++, 1) eq '{' or croak "Illegal $declarator definition";

	my $insert = sprintf "'$method', %s ($proto) { ", $declarator eq "around" ? "_around" : "method";
	$insert .= "BEGIN { Neverhood::Base::Declare::on_method_modifier_end() } ";
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);

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

sub trigger_or_builder_parser {
	# parses
	# trigger foo { ... }
	# into
	# trigger method _foo_trigger ($new, $old?) { ... }

	# or
	# rw foo => Int, trigger { ... };
	# into
	# rw foo => Int, trigger method ($new, $old?) { ... };

	# or
	# rw foo => Int, trigger;
	# into
	# rw foo => Int, trigger;

	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;
	my $is_trigger = $declarator eq 'trigger';

	$self->skip_declarator;
	$self->skipspace;

	my $name = $self->strip_name;
	my $proto = $self->strip_proto;
	my $line = $self->get_linestr;
	my $pos = $self->offset;
	
	return if !defined $name and substr($line, $pos, 1) ne "{";
	$proto //= '$new, $old' if $is_trigger;
	
	my $insert = "method ";
	if (defined $name) {
		$insert .= "_${declarator}_$name";
	}
	$insert .= "($proto)" if defined $proto;
	
	substr($line, $pos, 0) = $insert;
	$self->set_linestr($line);

	return;
}

sub class_or_role_parser {
	# parses
	# class Foo::Bar {
		# ...
	# }
	# into
	# class; {
		# package Foo::Bar;
		# use Neverhood::Base ':class';
		# {
			# ...
			# no Neverhood::Base;
			# __PACKAGE__->meta->make_immutable;
			# our @_WITH;
			# Mouse::with(@_WITH) if @_WITH;
		# }
	# }
	# 1;

	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;
	my $is_role = $declarator eq "role" ? 1 : 0;

	my $line = $self->get_linestr;
	$self->skip_declarator;
	my $start_pos = $self->offset;
	$self->skipspace;

	my $pos = $self->offset;
	my $len = Devel::Declare::toke_scan_ident($self->offset);
	$len or croak "Expected word after $declarator";
	my $package = substr($line, $pos, $len);

	$self->inc_offset($len);
	$self->skipspace;
	$pos = $self->offset;
	substr($line, $pos++, 1) eq '{' or croak "Illegal $declarator definition";

	my $insert = sprintf "; { package $package; use Neverhood::Base ':%s'; ",
		$is_role ? "role" : "class";
	$insert .= "{ BEGIN { Neverhood::Base::Declare::on_class_or_role_end($is_role) } ";
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);

	return;
}

sub on_class_or_role_end {
	my ($is_role) = @_;
	on_scope_end {
		my $line = Devel::Declare::get_linestr;
		my $pos = Devel::Declare::get_linestr_offset;
		my $package = Devel::Declare::get_curstash_name;
		my $insert =  " no Neverhood::Base; ";
		$insert .= "Neverhood::Base::Declare::process_with($is_role); ";
		$insert .=  "$package->meta->make_immutable; " if !$is_role;
		$insert .= "} 1; ";
		substr($line, $pos, 0) = $insert;
		Devel::Declare::set_linestr($line);
	}
}

# delayed with processing
my %does;
sub with {
	$does{scalar caller} = [@_];
}

sub process_with {
	my ($is_role) = @_;
	my $caller = caller;
	return if !exists $does{$caller};
	@_ = @{$does{$caller}};
	delete $does{$caller};
	goto $is_role ? \&Mouse::Role::with : \&Mouse::with;
}

1;
