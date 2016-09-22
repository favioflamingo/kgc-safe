# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Kgc-SafeCompartment.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use CBitcoin;

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

my $compartment = Kgc::Safe->new();


$compartment->class_add(
	'CBitcoin::CBHD',{
		'generate' => \&CBitcoin::CBHD::generate
		,'new' => \&CBitcoin::CBHD::new
		,'export_xprv' => \&CBitcoin::CBHD::export_xprv
		,'export_xpub' => \&CBitcoin::CBHD::export_xpub
		,'deriveChildPubExt' => \&CBitcoin::CBHD::deriveChildPubExt
		,'deriveChild' => \&CBitcoin::CBHD::deriveChild
	}
);




ok($compartment->reval($unsafe_code) eq 'xpub68sS2KgURMqihLe6XqgH7AMGqWdcf36XP2zmsN1ibz1mfoxwby9QHGai4T1ESVEqPBLwn2csnNNq4jxR6c6NMxkKqJgzs5ZVcdcmZaUNFBo'
, 'xpub matches');




__DATA__

my $x = new('CBitcoin::CBHD','new','xprv9s21ZrQH143K2mvmD7gyX7eaki1Z2xDLm1mv2acauXyXT9Jt5RbxaJY2pijhEomfmuMbQV78Lq6n6ephw8SToQBKhozVprCAuY8CBsGeBmF');

my $y = $x->('deriveChildPubExt',32);

return $y->('export_xpub');
