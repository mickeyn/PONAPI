package PONAPI::DAO::Request::CreateRelationships;

use Moose;

use PONAPI::DAO::Constants;

extends 'PONAPI::DAO::Request';
with 'PONAPI::DAO::Request::Role::UpdateLike';

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
    my ( $self, $repo ) = @_;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        eval {
            my @ret = $repo->create_relationships( %{ $self } );
            if ( $self->_verify_repository_response(@ret) ) {
                $self->_add_success_meta(@ret)
                    if $self->_verify_update_response($repo, @ret);
            }
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $self->_server_failure;
        };
    }

    return $self->response();
}

sub _validate_rel_type {
    my ( $self, $repo ) = @_;
    return unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    if ( !$repo->has_relationship( $type, $rel_type ) ) {
        $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 );
    }
    elsif ( !$repo->has_one_to_many_relationship( $type, $rel_type ) ) {
        $self->_bad_request( "Types `$type` and `$rel_type` are one-to-one" );
    }
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
