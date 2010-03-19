use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Schematron',
    'VERSION_FROM' => 'lib/XML/Schematron.pm', # finds $VERSION
    'PREREQ_PM' => {
        XML::SAX        => 0,
        XML::LibXML     => 0,
        XML::LibXSLT    => 0,
     },
);
