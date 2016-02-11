# ABSTRACT: DAO request role - `filter`
package PONAPI::DAO::Request::Role::HasFilter;

use Moose::Role;

has filter => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        "has_filter" => 'count',
    },
);

sub _validate_filter {
    my ( $self, $args ) = @_;

    return unless defined $args->{filter};

    $self->has_filter
        or $self->_bad_request( "`filter` is missing values" );

    return;
}

no Moose::Role; 1;

__END__
