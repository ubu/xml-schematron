package XML::Schematron::SchemaReader;
use Moose;
use MooseX::NonMoose;
extends 'XML::SAX::Base';

use XML::Schematron::Test;
use Data::Dumper;

has test_stack => (
    traits      => ['Array'],
    is          =>  'rw',
    isa         =>  'ArrayRef[XML::Schematron::Test]',
    default     =>  sub { [] },
    handles     => {
        add_test    => 'push',
    }
);

has [qw|context test_type expression|] => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str', 
    required    => 1,
);

has pattern => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str', 
    required    => 1,
    default     => sub { '[none]' },
);

has message => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str', 
    required    => 1,
    handles     => {
          add_to_message     => 'append',
          reset_message     => 'clear',
    },

);

sub start_element {
    my ($self, $el) = @_;
    #warn "processing element " . $el->{LocalName} . "\n";

    # simplify
    my $attrs = {};
    foreach my $attr ( keys ( %{$el->{Attributes}} ) ) {
        $attrs->{$el->{Attributes}->{$attr}->{LocalName}} = $el->{Attributes}->{$attr}->{Value};
    }
    
    #warn "EL " . Dumper( $el );

    if ( defined( $attrs->{context} )) {
        $self->context( $attrs->{context} );
    }


    if (( $el->{LocalName} =~ /(assert|report)$/)) {
        if ( defined( $attrs->{test} )) {
            $self->expression( $attrs->{test} );
        }
        else {
            warn "Schema Warning: Assert/Report element found with no associated 'test' attribute.";
            $self->expression('');
        }
    }
    elsif ($el->{LocalName} eq 'pattern' && defined( $attrs->{name} )) {
        $self->pattern( $attrs->{name} );
    }
}

sub end_element {
    my ($self, $el) = @_;
    
    if (( $el->{LocalName} =~ /(assert|report)$/)) {
        $self->test_type( $el->{LocalName} );

        my $test = XML::Schematron::Test->new(
                        test_type   => $self->test_type,
                        expression  => $self->expression,
                        context     => $self->context,
                        message     => $self->message,
                        pattern     => $self->pattern,
                    );
                    
        $self->add_test( $test );
        $self->reset_message;
    }
}

sub characters {
    my ($self, $characters) = @_;
    $self->add_to_message( $characters->{Data} );
}

# after 'end_document' => sub {
#     return [qw|foo bar bax quuuux|];
# };

no Moose;
__PACKAGE__->meta->make_immutable;

=cut

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

