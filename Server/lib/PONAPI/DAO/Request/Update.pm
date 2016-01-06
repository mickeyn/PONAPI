# ABSTRACT: DAO request - update
package PONAPI::DAO::Request::Update;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::UpdateLike',
     'PONAPI::DAO::Request::Role::HasDataAttribute',
     'PONAPI::DAO::Request::Role::HasDataMethods',
     'PONAPI::DAO::Request::Role::HasID';

has '+update_nothing_status' => (
    # http://jsonapi.org/format/#crud-updating-responses-404
    default => sub { 404 },
);

sub execute {
    my $self = shift;

    if ( $self->is_valid ) {
        my @ret = $self->repository->update( %{ $self } );

        $self->_add_success_meta(@ret)
            if $self->_verify_update_response(@ret);
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
