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
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_bad_request_data',
);

has sql_error => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sql_error',
);

# Picked from Throwable::Error
sub as_string {
    my ($self) = @_;

    my $str = $self->message;
    $str .= "\n\n" . $self->stack_trace->as_string;

    return $str;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__