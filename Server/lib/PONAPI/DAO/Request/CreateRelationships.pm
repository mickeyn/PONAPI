package PONAPI::DAO::Request::CreateRelationships;

use Moose;

use PONAPI::DAO::Constants;

extends 'PONAPI::DAO::Request';

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
            my $ret = $repo->create_relationships( %{ $self } );

# ???
            if ( !exists $PONAPI_UPDATE_RETURN_VALUES{$ret} ) {
                die ref($self->repository), "->create_relationships returned an unexpected value";
            }

            # http://jsonapi.org/format/#crud-updating-responses-409
            if ( $PONAPI_ERROR_RETURN{$ret} ) {
                $doc->set_status(409) if $ret == PONAPI_CONFLICT_ERROR;
            }
            else {
                $doc->add_meta(
                    message => "successfully created the relationship /"
                             . $self->type
                             . "/"
                             . $self->id
                             . "/"
                             . $self->rel_type
                             . " => "
                             . JSON::XS->new->canonical()->encode( $self->data )
                );
            }
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
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
