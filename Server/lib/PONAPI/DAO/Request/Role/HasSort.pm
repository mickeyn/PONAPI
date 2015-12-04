package PONAPI::DAO::Request::Role::HasSort;

use Moose::Role;

has sort => (
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { +[] },
    handles  => {
        "has_sort" => 'count',
    },
);

sub _validate_sort {
    my $self = shift;

    $self->has_sort
        or $self->_bad_request( "`sort` is missing values" );

    return;
}

no Moose::Role; 1;
__END__
