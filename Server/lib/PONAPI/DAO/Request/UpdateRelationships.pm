package PONAPI::DAO::Request::UpdateRelationships;

use Moose;

use PONAPI::DAO::Constants;

extends 'PONAPI::DAO::Request';
with 'PONAPI::DAO::Request::Role::UpdateLike';

has data => (
    is        => 'ro',
    isa       => 'Maybe[HashRef|ArrayRef]',
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
            my @ret = $repo->update_relationships( %{ $self } );

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


__PACKAGE__->meta->make_immutable;
no Moose; 1;
