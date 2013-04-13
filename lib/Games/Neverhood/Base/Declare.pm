use 5.01;
use strict;
use warnings;

package Games::Neverhood::Base::Declare;
use base 'Devel::Declare::Context::Simple', 'Method::Signatures';
use Carp qw/croak/;
our @CARP_NOT = 'Devel::Declare';
use B::Hooks::EndOfScope;
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [
		qw/ x func method _around class role /,
	],
);

sub x ($) { Games::Neverhood::ResourceKey->new(@_) }
sub func    (&) {}
sub method  (&) {}
sub _around (&) {}
sub class () {};
sub role  () {};

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
	$len or croak "Expected word after $declarator";
	my $method = substr($line, $pos, $len);

	$self->inc_offset($len);
	$self->skipspace;
	my $proto = $self->strip_proto // '';
	$self->skipspace;
	$line = $self->get_linestr;
	$pos = $self->offset;
	substr($line, $pos++, 1) eq '{' or croak "Illegal $declarator definition";

	my $insert = sprintf "'$method', %s ($proto) { ", $declarator eq "around" ? "_around" : "method";
	$insert .= "BEGIN { Games::Neverhood::Base::Declare::on_method_modifier_end() } ";
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

sub class_or_role_parser {
	# parses
	# class Foo::Bar {
		# ...
	# }
	# into
	# class; {
		# package Foo::Bar;
		# use Games::Neverhood::Base ':class';
		# {
			# ...
			# no Games::Neverhood::Base;
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

	my $insert = sprintf "; { package $package; use Games::Neverhood::Base ':%s'; ",
		$is_role ? "role" : "class";
	$insert .= "{ BEGIN { Games::Neverhood::Base::Declare::on_class_or_role_end($is_role) } ";
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
		my $insert =  " no Games::Neverhood::Base; ";
		$insert .= sprintf 'our @_WITH; %s::with(@_WITH) if @_WITH; undef @_WITH; ',
			$is_role ? "Mouse::Role" : "Mouse";
		$insert .= sprintf 'delete $%s::{_WITH}; ', $package;
		$insert .=  "$package->meta->make_immutable; " if !$is_role;
		$insert .= "} 1; ";
		substr($line, $pos, 0) = $insert;
		Devel::Declare::set_linestr($line);
	}
}

1;
