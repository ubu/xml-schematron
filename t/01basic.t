use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use XML::Schematron;
$loaded = 1;
ok(1);

my $tron = XML::Schematron->new();
ok($tron);
