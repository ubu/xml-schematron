package XML::Schematron;

use strict;
use XML::Parser::PerlSAX;

use vars qw/$VERSION/;

$VERSION = '0.98';

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = { schema => $args{schema} || '',
                  tests  => $args{tests}  || []};
    bless ($self, $class);
    return $self;
}

sub build_tests {
    my $self = shift;
    my $schema = $_[0] || $self->{schema};
    my $sax_handler = SchematronReader->new();
    my $sax_parser = XML::Parser::PerlSAX->new( Handler => $sax_handler);
    $sax_parser->parse(Source => {SystemId => $schema});
    push (@{$self->{tests}}, @{$sax_handler->{tests}});

    # switch back when Orchard matures
    # push (@{$self->{tests}}, $sax_parser->parse($schema));

}

sub add_test {
    my $self = shift;
    my %args = @_;
    $args{pattern} ||= '[none]';
#   print "adding test $args{expr}, $args{context}, $args{message}, $args{type}, $args{pattern} \n";
    push (@{$self->{tests}}, [$args{expr}, $args{context}, $args{message}, $args{type}, $args{pattern}]);    
}

sub tests {
    my $self = shift;
    return $_[0] ? $self->{tests} = $_[0] : $self->{tests};
}

sub schema {
    my $self = shift;
    return $_[0] ? $self->{schema} = $_[0] : $self->{schema};
}
1;

package SchematronReader;
use strict;

use vars qw/$context $current_ns $action $message $test @tests $pattern/;

sub new {
    my $type = shift;
    return bless {}, $type;
}

sub start_element {
    my ($self, $el) = @_;
    my ($package, $filename, $line) = caller;
    
    # warn "Starting element $el->{Name}\n";

    # switch back when Orchard matures

    my %attrs = %{$el->{Attributes}};

    #foreach my $attr (keys %{$el->{Attributes}}) {
    #    $attrs{$el->{Attributes}->{$attr}->{LocalName}} = $el->{Attributes}->{$attr}->{Value};
    #}

    $context = $attrs{context} if ($attrs{context});

    if (($el->{Name} =~ /(assert|report)$/)) {
        $test = $attrs{test};
    }
    elsif ($el->{Name} eq 'pattern') {
        $pattern = $attrs{name};
    }
}

sub end_element {
    my ($self, $el) = @_;
    my ($ns, $test_type);
    if (($el->{Name} =~ /(assert|report)$/)) {
        if ($el->{Name} =~ /^(.+?):(.+?)$/) {
            $ns = $1;
            $test_type = $2;
        }
        else {
            $test_type = $el->{Name};
        }

        push (@tests, [$test, $context, $message, $test_type, $pattern]);
        $message = ''; 
    }
}

sub characters {
    my ($self, $characters) = @_;
    if ($characters->{Data} =~ /[^\s\n]/g) {
        my $chars = $characters->{Data};
        $chars =~ s/\B\s\.?//g;
        $message .= $chars
    }
}

sub end_document {
     my $self = shift;
     # when the doc ends, return the tests
     $self->{tests} =  \@tests;
}

sub start_document {
    # sax conformance only.
}

sub processing_instruction {
    # sax conformance only.
}

sub comment {
    # sax conformance only.
}


1;

package XML::SchematronXSLTProcessor;

use vars qw/@ISA/; 
        
@ISA = qw/XML::Schematron/;

sub tests_to_xsl {
    my $self = shift;
    my $template;
    my $mode = 'M0';
    my $ns = qq{xmlns:xsl="http://www.w3.org/1999/XSL/Transform"};
        
    $template = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <xsl:stylesheet $ns version="1.0">
    <xsl:output $ns method="text"/>
    <xsl:template $ns match="/">
    <xsl:apply-templates $ns select="/" mode="$mode"/>};
        
            
    my $last_context_path = '';
    my $priority = 4000;
    foreach my $testref (@{$self->{tests}}) {
        my ($test, $context_path, $message, $test_type, $pattern) = @{$testref};
        $context_path =~ s/"/'/g if $context_path =~ /"/g;
        $test =~ s/</&lt;/g;
        $test =~ s/>/&gt;/g;
        $message =~ s/\n//g;
        $message .= "\n";
    
        if ($context_path ne $last_context_path) {
             $template .= qq{\n<xsl:apply-templates $ns mode="$mode"/>\n} unless $priority == 4000;
             $template .= qq{</xsl:template>\n<xsl:template $ns match="$context_path" priority="$priority" mode="$mode">};
             $priority--;
        }
    
        if ($test_type eq 'assert') {
            $template .= qq{<xsl:choose $ns>
                            <xsl:when $ns test="$test"/>
                            <xsl:otherwise $ns>In pattern $pattern: $message</xsl:otherwise>
                            </xsl:choose>};
        }
        else {
            $template .= qq{<xsl:if $ns test="$test">In pattern $pattern: $message</xsl:if>};
        }
        $last_context_path = $context_path;
    }
        
        
    $template .= qq{<xsl:apply-templates $ns mode="$mode"/>\n</xsl:template>\n
                    <xsl:template xmlns:xsl="http://www.w3.org/1999/XSL/Transform" match="text()" priority="-1" mode="M0"/>
                    </xsl:stylesheet>};
        
    #print "$template\n";
    return $template;
}

sub dump_xsl {
    my $self = shift;
    my $stylesheet = $self->tests_to_xsl;;
    return $stylesheet;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Schematron - Perl implementation of the Schematron.

=head1 SYNOPSIS

  This package should not be used directly. Use one of the subclasses instead.

=head1 DESCRIPTION

This is the superclass for the XML::Schematron::* modules.

Please run perldoc XML::Schematron::XPath, or perldoc XML::Schematron::Sablotron for examples and complete documentation.

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2000 Kip Hampton. All rights reserved. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=head1 SEE ALSO

For information about Schematron, sample schemas, and tutorials to help you write your own schmemas, please visit the
Schematron homepage at: http://www.ascc.net/xml/resource/schematron/

=cut
