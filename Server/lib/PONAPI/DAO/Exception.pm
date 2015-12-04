package PONAPI::DAO::Exception;
use Moose;
use Moose::Util qw/find_meta/;
with 'Throwable', 'StackTrace::Auto';

use overload
    q{""}    => 'as_string',
    fallback => 1;

has message => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has status => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 400 },
);

has bad_request_data => (
    is  => 'ro',
    isa => 'Bool',
);

has sql_error => (
    is  => 'ro',
    isa => 'Bool',
);

# Picked from Throwable::Error
sub as_string {
    my $self = shift;
    return $self->message . "\n\n" . $self->stack_trace->as_string;
}

sub as_response {
    my ($self) = @_;

    my $status = $self->status;
    my $detail = $self->message;

    return $status, [], +{
        jsonapi => { version  => "1.0" },
        errors  => [ { detail => $detail, status => $status } ],
    };
}

sub new_from_exception {
    my ($class, $e, $dao) = @_;

    my ($status, $message) = $class->_handle_exception_obj($e, $dao);

    if ( !$status || !$message ) {
        $status  = 500;
        $message = "A fatal error has occured, please check server logs";
        warn "$e";
    }

    return $class->new(
        message => $message,
        status  => $status,
    );
}

sub _handle_exception_obj {
    my ($self, $e, $dao) = @_;
    return unless blessed($e);
    return unless $e->isa('Moose::Exception');

    if ( $e->isa('Moose::Exception::AttributeIsRequired') ) {
        my $attribute = $e->attribute_name;

        return 400, "Parameter `$attribute` is required";
    }
    elsif ( $e->isa('Moose::Exception::ValidationFailedForTypeConstraint') || $e->isa('Moose::Exception::ValidationFailedForInlineTypeConstraint') ) {
        my $class      = find_meta( $e->class_name );
        my $attribute  = $class->get_attribute( $e->attribute_name );
        my $value_nice = $dao->json->encode( $e->value );

        if ( !$attribute ) {
            my $attr = $e->attribute_name;
            return 400, "Parameter `$attr` got an expected data type: $value_nice";
        }

        my $attribute_name = $attribute->name;
        my $type_name      = $attribute->{isa};

        my $type_name_nice = _moose_type_to_nice_description($type_name);
        my $message = "Parameter `$attribute_name` expected $type_name_nice, but got a $value_nice";
        
        return 400, $message;
    }
    
    return;
}

# THIS IS NOT COMPLETE, NOR IS IT MEANT TO BE
sub _moose_type_to_nice_description {
    my ($type_name) = @_;

    $type_name =~ s/ArrayRef/Collection/g;
    $type_name =~ s/HashRef/Resource/g;
    $type_name =~ s/Maybe\[(.+)]/null or $1/g;
    $type_name =~ s/\|/ or /g;
    
    return $type_name;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
