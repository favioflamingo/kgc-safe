# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Kgc-SafeCompartment.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Safe;
use CBitcoin::CBHD;
use Test::More tests => 2;
BEGIN { use_ok('Kgc::Safe') };


############ load in the unsafe code ##########

my $unsafe_code = '';
while(<DATA>){
	$unsafe_code .= $_;
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $compartment = new Safe;

# extremely limit what can be run
$compartment->permit_only(qw(:default));


########################

# allow CBHD stuff
my $dispatch_constructor = {
	'deriveChild' => \&CBitcoin::CBHD::deriveChild
};


my $dispatch_methods = {
	'export_xprv' =>  \&CBitcoin::CBHD::export_xprv
};


sub base {
	my $x = shift;
	
	warn "P1:$x";
	
	return sub{
		my $subname = shift;
		
		my $class_name = 'CBitcoin::CBHD';
		my $obj = $x;
		#my $dc = $dispatch_constructor;
		my $dm = $dispatch_methods;
		
		warn "Obj:".ref($obj);
			
		if(defined $obj && defined $dm->{$subname}){
			return $dm->{$subname}->($obj,@_);
		}
		else{
			return undef;
		}
	};	
}



sub generate{
	
	my $x = CBitcoin::CBHD->generate();

	return sub{
		my $subname = shift;
		
		my $class_name = 'CBitcoin::CBHD';
		my $obj = $x;
		#my $dc = $dispatch_constructor;
		my $dm = $dispatch_methods;
			
		if(defined $obj && defined $dm->{$subname}){
			
			return $dm->{$subname}->($obj,@_);
		}
		else{
			return 0;
		}
	};
}

my $var1 = 1;

sub increment{
	my $v2 = \$var1;
	my $buf;
	
	my $x = CBitcoin::CBHD->generate();
	
	$x->export_xprv();
	
	open(my $fh,'<','/dev/urandom');
	sysread($fh,$buf,4);
	close($fh);
	$$v2 += unpack('l',$buf);
	return $$v2;
}

$compartment->share('&increment');


my $result = $compartment->reval($unsafe_code) || '';
#warn "X=".CBitcoin::CBHD->generate()->export_xprv()."\n";
warn "Result=$result\n";


ok(1, 'nothing');




__DATA__

increment();

increment();

return increment();
