package XML::Schematron::Sablotron;

use strict;
use XML::Schematron;
use XML::Sablotron;

use vars qw/@ISA $VERSION/;

@ISA = qw/XML::SchematronXSLTProcessor/;
$VERSION = '0.98';

sub verify {
    my $self = shift;    
    my $xml = shift;
    my ($data, $do_array);
    $do_array++ if wantarray;

    $self->build_tests if $self->{schema};

    my $template = $self->tests_to_xsl;
    #print "$template\n";

    if ( $xml =~ /^\s*<\?\s*(xml|XML)\b/ ) {
        $data = $xml;
    }
    else {
        open (XML, "$xml") || die "Could not open file $xml $!\n"; 
        local $/;
        $data = <XML>;
        close XML;
    }

    my $xslt_processor = XML::Sablotron->new();
    my $result = ' ';

    my $args = ['template', "$template", 'xml_resource', "$data"];

    my $retcode = $xslt_processor->RunProcessor("arg:/template", "arg:/xml_resource", "arg:/result", 
                                                [], $args);
        if ($retcode) {
          die "Sablotron could not process the XML file";
        }

   my $ret_string = $xslt_processor->GetResultArg("result");

   if ($do_array) {
       my @ret_array = split "\n", $ret_string;
       return @ret_array;
   }

   return $ret_string;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Schematron::Sablotron - Perl extension for validating XML with XPath/XSLT expressions.

=head1 SYNOPSIS


  use XML::Schematron::Sabotron;
  my $pseudotron = XML::Schematron::Sablotron->new(schema => 'my_schema.xml');
  my $messages = $pseudotron->verify('my_doc.xml');

  if ($messages) {
      # we got warnings or errors during validation...
      ...
  }

  OR, in an array context:

  my $pseudotron = XML::Schematron::Sablotron->new(schema => 'my_schema.xml');
  my @messages = $pseudotron->verify('my_doc.xml');


  OR, just get the generated xsl:

  my $pseudotron = XML::Schematron::Sablotron->new(schema => 'my_schema.xml');
  my $xsl = $pseudotron->dump_xsl; # returns the internal XSLT stylesheet.


=head1 DESCRIPTION

XML::Schematron::Sablotron serves as a simple validator for XML based on Rick JELLIFFE's Schematron XSLT script. A Schematron
schema defines a set of rules in the XPath language that are used to examine the contents of an XML document tree.

A simplified example: 

 <schema>
  <pattern>
   <rule context="page">
    <assert test="count(*)=count(title|body)">The page element may only contain title or body elements.</assert> 
    <assert test="@name">A page element must contain a name attribute.</assert> 
    <report test="string-length(@name) &lt; 5">A page element name attribute must be at least 5 characters long.</report> 
   </rule>
  </pattern>
 </schema>

Note that an 'assert' rule will return if the result of the test expression is I<not> true, while a 'report' rule will return
only if the test expression evalutes to true.

=head1 METHODS

=over 4

=item new()
  
The 'new' constructor accepts the following "named" arguments:

=over 4

=item * schema

The filename of the schema to use for generating tests.

=item * tests

The tests argument is an B<alternative> to the use of a schema as a means for defining the test stack. It should be a 
reference to a list of lists where the format of the sub-lists must conform to the following order:

  [$xpath_exp, $context, $message, $test_type, $pattern]
      
=back

=item schema()

When called with a single scalar as its argument, this method sets/updates the schema file to be used for generatng
tests. Otherwise, it simply returns the name of the schema file (if any).

=item tests()

When called with a reference to a list of lists as its argument (see the format in the description of the 'tests' argument to 
the new() method for details), this method sets the current test stack. Otherwise, it returns an arrayref to the current test 
stack (if any).

=item add_test(%args);

The add_test() method allows you push additional tests on to the stack before validation using the typical "hash of named
parameters" style.

Arguments for this method:

=over 4

=item * expr (required)

The XPath expression to evaluate.
                 
=item * context (required)

An element name or XPath location to use as the context of the test expression.

=item * type (required)

The B<type> argument must be set to either 'assert' or 'report'. Assert tests will return the associated message only if the
the corresponding test expression is B<not> true, while 'report' tests will return only if their associated test expression
B<are> true.

=item * message (required)

The text message to display when the test condition is met.

=item * pattern (optional)

Optional descriptive text for the returned message that allows a logical grouping of tests.

Example:

      
  $obj->add_test(expr => 'count(@*) > 0',
                 context => '/pattern',
                 message => 'Pattern should have at least one attribute',
                 type => 'assert',
                 pattern => 'Basic tests');

Note that add_test() pushes a new test on to the existing test list, while tests() redefines the entire list.

=back

=item verify('my_xml_file.xml' or $some_xml_string)

The verify() method takes the path to the XML document that you wish to validate, or a scalar containing the entire document  
as a string, as its sole argument. It returns the messages  that are returned during validation. When called in an array
context, this method returns an array of the messages generated during validation. When called in a scalar context, this
method returns a concatenated string of all output.

=item dump_xsl;

The dump_xsl method will return the internal XSLT script created from your schema.

=back

=head1 CONFORMANCE

Internally, XML::Schematron::Sablotron uses the Sablotron XSLT proccessor and, while this proccessor is not 100% compliant
with the XSLT spec at the time of this writing, it is evolving quickly and is very near completion. It is therefore possible
that you might use a completely valid XSLT expression within one of your schema's tests that will cause this module to die
unexpectedly. 

For those platforms on which Sablotron is not available, please see the documentation for XML::Schematron::XPath (also in this
distribution) for an alternative. 

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2000 Kip Hampton. All rights reserved. This program is free software; you can redistribute it and/or modify it  
under the same terms as Perl itself.

=head1 SEE ALSO

For information about Schematron, sample schemas, and tutorials to help you write your own schmemas, please visit the
Schematron homepage at: http://www.ascc.net/xml/resource/schematron/

For information about how to install Sablotron and the necessary XML::Sablotron Perl module, please see the Ginger Alliance
homepage at: http://www.gingerall.com/ 

For detailed information about the XPath syntax, please see the W3C XPath Specification at: http://www.w3.org/TR/xpath.html 

=cut
