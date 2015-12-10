# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::DAO::Request::Role::HasPage;

use Moose::Role;

has page => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        "has_page" => 'count',
    },
);

sub _validate_page {
    my $self = shift;

    $self->has_page
        or $self->_bad_request( "`page` is missing values" );

    return;
}

no Moose::Role; 1;

__END__
