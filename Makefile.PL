use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Schematron',
    'VERSION_FROM' => 'Schematron.pm', # finds $VERSION
    'PREREQ_PM' => {XML::Parser::PerlSAX},
);
