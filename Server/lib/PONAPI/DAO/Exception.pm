package PONAPI::DAO::Exception;
use Moose;
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

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
