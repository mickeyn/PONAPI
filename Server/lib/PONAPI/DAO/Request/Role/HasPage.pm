# ABSTRACT: DAO request role - `page`
package PONAPI::DAO::Request::Role::HasPage;

use Moose::Role;

has page => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    handles  => {
        "has_page" => 'count',
    },
);

sub _validate_page {
    my ( $self, $args ) = @_;

    return unless defined $args->{page};

    $self->has_page
        or $self->_bad_request( "`page` is missing values" );

    return;
}

no Moose::Role; 1;

__END__
