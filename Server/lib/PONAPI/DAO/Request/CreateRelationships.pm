package PONAPI::DAO::Request::CreateRelationships;

use Moose;

use PONAPI::DAO::Constants;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::UpdateLike',
     'PONAPI::DAO::Request::Role::HasDataMethods',
     'PONAPI::DAO::Request::Role::HasID',
     'PONAPI::DAO::Request::Role::HasRelationshipType';

has data => (
    is        => 'ro',
    isa       => 'ArrayRef[HashRef]',
    predicate => 'has_data',
);

sub BUILD {
    my $self = shift;

    $self->check_has_id;
    $self->check_has_rel_type;
    $self->check_has_data;
}

sub execute {
    my $self = shift;

    if ( $self->is_valid ) {
        local $@;
        eval {
            my @ret = $self->repository->create_relationships( %{ $self } );
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

sub _validate_rel_type {
    my $self = shift;
    return unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    if ( !$self->repository->has_relationship( $type, $rel_type ) ) {
        $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 );
    }
    elsif ( !$self->repository->has_one_to_many_relationship( $type, $rel_type ) ) {
        $self->_bad_request( "Types `$type` and `$rel_type` are one-to-one" );
    }
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
