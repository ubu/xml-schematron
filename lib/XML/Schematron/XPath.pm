package XML::Schematron::XPath;

use strict;
use XML::Schematron;
use XML::XPath;

use vars qw/@ISA $VERSION/;

@ISA = qw/XML::Schematron/;
$VERSION = '0.98';

sub verify {
    my $self = shift;    
    my $xml = shift;
        
    my ($ret_strings, $do_array, @ret_array);
    $do_array++ if wantarray;

    $self->build_tests if $self->{schema};

    #TODO: let 'em invisibly pass filehandles, too.

    my $xp;
         
    if ( $xml =~ /^\s*<\?\s*(xml|XML)\b/ ) {     
        $xp = XML::XPath->new(xml => $xml);
    }
    else {
        $xp = XML::XPath->new(filename => $xml);
    }


    foreach my $testref (@{$self->{tests}}) {
        # some needless duplication here but it enhances readability
        my ($test, $context_path, $message, $test_type, $pattern) = @{$testref};
        my $step_count = 0;
        my $node_count = 0;
        my $context = 0;
        $message =~ s/\n/\s/g;

        # make sure our search is global unless they specified a path
        $context_path = qq{//$context_path} unless $context_path =~ m|^/|; 

#        debugging is our friend
#        print "test is $test \n"; 
#        print "context path is $context_path\n";
#        print "message is  $message\n";
#        print "type $test_type\n";

        # here's the beef...
        # it seems too simple (and probably is) :>

        foreach my $node ($xp->findnodes($context_path)->get_nodelist) {
                $step_count++ if $node->find($test);
        }

        if ($test_type eq 'assert') {      
            my $dupe_node = $xp->findnodes($context_path);
            $node_count = $dupe_node->size;
        }
        else {
            $node_count = 0;
        }

         #print "node_count for $test is $node_count step_count is $step_count\n";
        
        if ($node_count != $step_count) {
            if ($do_array) {
                push (@ret_array, "In pattern $pattern: $message");
            }
            else {
                $ret_strings .= "In pattern $pattern: $message\n";
            }
        }
    }

    return $do_array ? @ret_array : $ret_strings;  
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Schematron::XPath - Perl extension for validating XML with XPath expressions.

=head1 SYNOPSIS

  use XML::Schematron::XPath;
  my $pseudotron = XML::Schematron::XPath->new(schema => 'my_schema.xml');
  my $messages = $pseudotron->verify('my_file.xml');

  if ($messages) {
      # we got warnings or errors during validation...
      ...
  }
  
  OR, in an array context

  my @messages = $pseudotron->verify('my_file.xml');

=head1 DESCRIPTION

XML::Schematron::XPath serves as a simple validator for XML based on Rick JELLIFFE's Schematron XSLT script. A Schematron
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

The B<type> argument must be set to either 'assert' or 'report'. Assert tests will return the associated message
only if the the corresponding test expression is B<not> true, while 'report' tests will return only if their associated test
expression B<are> true.  

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

=back

=head1 CONFORMANCE

XML::Schematron::XPath I<does not conform> to the current Schematron specification since more modern versions allow
XSLT-specific expressions to be used as tests. Please note, however, that robust validation is still quite possible using
just the XPath language. 

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2000 Kip Hampton. All rights reserved. This program is free software; you can redistribute it and/or modify it  
under the same terms as Perl itself.

=head1 SEE ALSO

For information about Schematron, sample schemas, and tutorials to help you write your own schmemas, please visit the
Schematron homepage at: http://www.ascc.net/xml/resource/schematron/

For detailed information about the XPath syntax, please see the W3C XPath Specification at: http://www.w3.org/TR/xpath.html 

=cut
