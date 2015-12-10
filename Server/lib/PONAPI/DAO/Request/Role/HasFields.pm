# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::DAO::Request::Role::HasFields;

use Moose::Role;

has fields => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        "has_fields" => 'count',
    },
);

sub _validate_fields {
    my $self = shift;
    return unless $self->has_fields;

    my $fields = $self->fields;
    foreach my $fields_type ( keys %$fields ) {
        if ( !$self->repository->has_type( $fields_type ) ) {
            $self->_bad_request( "Type `$fields_type` doesn't exist.", 404 );
        }
        else {
            $self->repository->type_has_fields($fields_type, $fields->{$fields_type})
                or $self->_bad_request(
                    "Type `$fields_type` does not have at least one of the requested fields"
                );
        }
    }
}

no Moose::Role; 1;

__END__
