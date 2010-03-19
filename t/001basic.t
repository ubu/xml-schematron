use Test::More;
use_ok('XML::Schematron');

my $tron = XML::Schematron->new( schema => 't/data/order.scm' );

isa_ok($tron, 'XML::Schematron', 'Schematron instance created');

my @errors = $tron->verify('t/data/order.xml');

ok( scalar @errors == 3, 'Three errors' );

done_testing();