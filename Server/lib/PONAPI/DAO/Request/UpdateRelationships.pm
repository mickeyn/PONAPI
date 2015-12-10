# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::DAO::Request::UpdateRelationships;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::UpdateLike',
     'PONAPI::DAO::Request::Role::HasDataMethods',
     'PONAPI::DAO::Request::Role::HasID',
     'PONAPI::DAO::Request::Role::HasRelationshipType';

has data => (
    is        => 'ro',
    isa       => 'Maybe[HashRef|ArrayRef]',
    predicate => 'has_data',
);

sub execute {
    my $self = shift;
    if ( $self->is_valid ) {
        local $@;
        eval {
            my @ret = $self->repository->update_relationships( %{ $self } );

            $self->_add_success_meta(@ret)
                if $self->_verify_update_response(@ret);

            1;
        } or do {
            my $e = $@;
            $self->_handle_error($e);
        };
    }

    return $self->response();
}

sub _validate_data {
    my $self = shift;

    # these are chained to avoid multiple errors on the same issue
    $self->check_data_has_type
        and $self->check_data_attributes()
        and $self->check_data_relationships();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
