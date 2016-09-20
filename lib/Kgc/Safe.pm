package Kgc::Safe;

use 5.020002;
use strict;
use warnings;

use Safe;


require Exporter;

our @ISA = qw(Exporter);


our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1';


=pod

---+ Stuff

   * [[http://search.cpan.org/~jhi/perl-5.8.0/ext/Opcode/Safe.pm]]

=cut





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
