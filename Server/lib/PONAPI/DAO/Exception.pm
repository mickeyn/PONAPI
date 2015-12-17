# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::DAO::Exception;

use Moose;
use Moose::Util  qw/find_meta/;
use Scalar::Util qw/blessed/;

with 'StackTrace::Auto';

sub throw {
  my $class_or_obj = shift;
  die $class_or_obj if blessed $class_or_obj;
  die $class_or_obj->new(@_);
}

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

has internal => (
    is  => 'ro',
    isa => 'Bool',
);

has json_api_version => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '1.0' },
    writer  => '_set_json_api_version'
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

    if ( $self->sql_error ) {
        $detail = "SQL error: $detail";
    }
    elsif ( $self->bad_request_data ) {
        $detail = "Bad request data: $detail";
    }
    else {
        $status = 500;
        warn $detail if $detail;
        $detail = "A fatal error has occured, please check server logs";
    }

    return $status, [], +{
        jsonapi => { version  => $self->json_api_version },
        errors  => [ { detail => $detail, status => $status } ],
    };
}

sub new_from_exception {
    my ($class, $e, $dao) = @_;

    if ( blessed($e) && $e->isa($class) ) {
        $e->_set_json_api_version( $dao->version );
        return $e;
    }

    my %args_for_new = $class->_handle_exception_obj($e, $dao);

    if ( !$args_for_new{status} || !$args_for_new{message} ) {
        %args_for_new = (
            status  => 500,
            message => '',
        );
        warn "$e";
    }

    return $class->new(
        %args_for_new,
        json_api_version => $dao->version,
    );
}

sub _handle_exception_obj {
    my ($self, $e, $dao) = @_;
    return unless blessed($e);
    return unless $e->isa('Moose::Exception');

    if ( $e->isa('Moose::Exception::AttributeIsRequired') ) {
        my $attribute = $e->attribute_name;

        return (
            status  => 400,
            message => "Parameter `$attribute` is required",
            bad_request_data => 1,
        );
    }
    elsif ( $e->isa('Moose::Exception::ValidationFailedForTypeConstraint') || $e->isa('Moose::Exception::ValidationFailedForInlineTypeConstraint') ) {
        my $class      = find_meta( $e->class_name );
        my $attribute  = $class->get_attribute( $e->attribute_name );
        my $value_nice = $dao->json->encode( $e->value );

        if ( !$attribute ) {
            my $attr = $e->attribute_name;
            return (
                status  => 400,
                message => "Parameter `$attr` got an expected data type: $value_nice",
                bad_request_data => 1,
            );
        }

        my $attribute_name = $attribute->name;
        my $type_name      = $attribute->{isa};

        my $type_name_nice = _moose_type_to_nice_description($type_name);
        my $message = "Parameter `$attribute_name` expected $type_name_nice, but got a $value_nice";

        return (
            status  => 400,
            message => $message,
            bad_request_data => 1,
        );
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
=encoding UTF-8

=head1 NAME

PONAPI::DAO::Exception - Exceptions for PONAPI

=head1 SYNOPSIS

    use PONAPI::DAO::Exception;
    PONAPI::DAO::Exception->throw( message => "Generic exception" );
    PONAPI::DAO::Exception->throw(
        message => "Explanation for the sql error, maybe $DBI::errstr",
        sql     => 1,
    );
    PONAPI::DAO::Exception->throw(
        message          => "Data had type `foo` but we wanted `bar`",
        bad_request_data => 1,
    );

=head1 DESCRIPTION

I<PONAPI::DAO::Exception> can be used by repositories to signal errors;
exceptions thrown this way will be caught by L<the DAO|PONAPI::DAO> and
handled gracefully.

Different kinds of exceptions can be thrown by changing the arguments
to C<throw>; C<sql =E<gt> 1> will throw a SQL exception,
C<bad_request_data =E<gt> 1> will throw an exception due to the
input data being wrong, and not passing any of those will
throw a generic exception.

The human-readable C<message> for all of those will end up in the
error response returned to the user.

=head1 METHODS

=head2 message

This attribute contains the exception message.

=head2 stack_trace

This contains the stack trace of the exception.

=head2 as_string

Returns a stringified form of the exception.  The object is overloaded
to return this if used in string context.

=head2 as_response

Returns the exception as a 3-element list that may be fed directly
to plack as a {json:api} response.

    $e->as_response; # ( $status, [], { errors => [ { detail => $message } ] } )

=head2 json_api_version

Defaults to 1.0; only used in C<as_response>.

=head2 status

HTTP Status code for the exception; in most cases you don't need to
set this manually.

=end
