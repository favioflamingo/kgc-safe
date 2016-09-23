package Safe::Compartment;

#use 5.020002;
use strict;
use warnings;

use Safe;
use Safe::Hole;

require Exporter;

our @ISA = qw(Exporter);


our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1';


=pod

---+ constructors

=cut


=pod

---++ new

=cut

sub new {
	my ($package) = @_;
	
	
	my $this = {
		'classes' => {}
		,'safe' => Safe->new('Root')
		,'hole' => Safe::Hole->new({})
		,'subs' => {}
	};
	
	bless($this,$package);
	
	return $this;
}

=pod

---+ getters/setters

=cut

=pod

---++ safe

=cut

sub safe{
	return shift->{'safe'};
}


=pod

---++ hole

The Safe::Hole object.

=cut

sub hole{
	return shift->{'hole'};
}

=pod

---+ class

=cut


=pod

---++ class_add($module_name,{'x'=> \&x,...},['new'])

To let users in safe compartments use object classes that would ordinarly be unsafe, store references to the appropriate subroutines here.

Then when the users use the 'new' sub in the safe compartment, they can safely access those classes without being able to access internal variables and/or use inappropriate subroutines.

This is basically the perl version of creating public/private class methods.

   * [[http://search.cpan.org/~jhi/perl-5.8.0/ext/Opcode/Safe.pm]]

=cut

sub class_add {
	my ($this,$module_name,$dispatch_table,$constructors) = @_;
	
	my $class = {
		'dispatch' => {}
	};
	
	die "no dispatch table" unless defined $dispatch_table && ref($dispatch_table) eq 'HASH';
	
	foreach my $x (keys %{$dispatch_table}){
		die "not a CODE reference" unless ref($dispatch_table->{$x}) eq 'CODE';
		
		$class->{'dispatch'}->{$x} = $dispatch_table->{$x};
		#warn "added ($module_name,$x)\n";
	}
	

	$this->{'classes'}->{$module_name} = $class;
}



=pod

---+ utilities

=cut

=pod

---++ dispatch($class_name,$sub_name,...args...)

This sub is called in the safe container.  Return an anonymous sub which will allow users in the compartment to access methods in the module.

=cut

sub dispatch{
	my $this = shift;
	my $class_name = shift;
	my $sub_name = shift;
	
	#warn "dispatch 1\n";
	
	return undef unless defined $class_name && $this->{'classes'}->{$class_name};
	my $class = $this->{'classes'}->{$class_name};
	#require Data::Dumper;
	#my $xo = Data::Dumper::Dumper($class);
	#warn "dispatch 2($class_name,$sub_name)\n";
	
	
	unless(defined $sub_name && defined $class->{'dispatch'}->{$sub_name}){
		# when no arguments are specified, return the ref()
		return $class_name;
	}
	
	
	
	#my $new_bool = 0;
	#$new_bool = 1 if $class->{'constructors'}->{$sub_name};
	
	#warn "dispatch 3:(".ref($class->{'dispatch'}->{$sub_name})."|".ref($y).")\n" if ref($y) eq 'CBitcoin::CBHD';

	# change args to objects
	my @args;
	while(my $a = shift(@_)){
		unless(ref($a) eq 'CODE'){
			push(@args,$a);
			next;
		}
		
		my $refname = $a->();
		
		unless(defined $refname && 0 < length($refname)){
			push(@args,$a);
			next;
		}
		
		# search and replace sub reference with the actual object
		if(defined $this->{'subs'}->{$a}){
			push(@args,$this->{'subs'}->{$a});
		}
		else{
			push(@args,$a);
		}
	}
	
	
	my $ans = $class->{'dispatch'}->{$sub_name}->(@args);
	#warn "dispatch: ans=$ans\n";
	
	unless(defined $ans){
		#warn "dispatch 4\n";
		return undef;
	}
	
	my $ref = ref($ans);
	
	if($ref =~ m/(SCALAR|ARRAY|HASH|CODE|REF|GLOB|LVALUE|FORMAT|IO|VSTRING|Regexp)/){
		return $ans;
	}
	elsif($ref eq ''){
		# this is a scalar
		return $ans;
	}
	elsif(defined $this->{'classes'}->{$ref}){
		# we have an object, create a subroutine to access this object
		#warn "dispatch: object=$ans\n";
		return $this->constructor($ans);
	}
	else{
		return $ans;
	}
}

=pod

---++ constructor($obj)->$sub

Create an anonymous subroutine to access an object.

=cut

sub constructor{
	my ($this,$obj) = @_;
	#warn "contructor 1\n";
	return undef unless defined $obj;
	#warn "contructor 2\n";
	my $module_name = ref($obj);
	return undef unless defined $this->{'classes'}->{$module_name};
	#warn "contructor 3\n";
	my $subvar = sub{
		my $obj_in = $obj;
		my $this_in = $this;
		my $sub_name = shift;
	
		return $this_in->dispatch(ref($obj_in),$sub_name,$obj_in,@_);	
	};
	# remember the object associated with the code
	$this->{'subs'}->{$subvar} = $obj;
	
	return $subvar;
}

=pod

---++ initialize_compartment

Let \&new be the official contructor inside the compartment.  To create a new object, just do:<verbatim>
my $obj = new('CBitcoin::CBHD','generate');

and $obj->() returns the name of the object.

=cut

sub initialize_compartment{
	my ($this) = @_;
	
	$this->{'initialized'} = 0;
	
	$this->{'safe'} = Safe->new('Root');
	
	$this->{'hole'} = Safe::Hole->new({});
	
	
	#warn "initializing";
	
	$this->hole->wrap(
		sub{
			my $t1 = $this;
			my $class_name = shift;
			return undef unless defined $class_name && $class_name =~ m/^([\:0-9a-zA-Z]+)$/;
			$class_name = $1;
			
			#warn "Got $class_name";
			my $mod_file;
			($mod_file = $class_name) =~ s{::}{/}g;
			$mod_file .= '.pm';
			require $mod_file;
			#warn "hole wrap 1\n";
			my $sub_name = shift;
			return undef unless defined $sub_name;
			#warn "hole wrap 2\n";
			return $t1->dispatch($class_name,$sub_name,$class_name,@_);
		}
		, $this->safe
		, '&create'
	);
	
	$this->hole->wrap(
		sub{
			my $this_in = $this;
			my $subvar = shift;
			return undef unless defined $subvar && ref($subvar) eq 'CODE' && defined $this_in->{'subs'}->{$subvar};
			delete $this_in->{'subs'}->{$subvar};
		}
		,$this->safe
		,'&destroy'
	);
}

=pod

---++ reval($code)

Evaluate the code and return the result.

=cut

sub reval{
	my ($this,$code) = @_;
	
	unless($this->{'initialized'}){
		$this->initialize_compartment();
	}
	
	return '' unless defined $code;
	
	return $this->safe->reval($code) // '';
}


1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kgc::SafeCompartment - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Kgc::SafeCompartment;
  

=head1 DESCRIPTION

Allow the execution of unsafe code.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Please see the github repo for further documenation.

http://e-flamingo.net

=head1 AUTHOR

Joel DeJesus, E<lt>dejesus.joel@e-flamingo.jp<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joel DeJesus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
