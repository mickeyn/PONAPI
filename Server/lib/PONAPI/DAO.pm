# ABSTRACT: PONAPI::DAO
package PONAPI::DAO;
use Moose;

use PONAPI::DAO::Repository;
use PONAPI::DAO::Request;
use PONAPI::Builder::Document;

use JSON::XS qw< encode_json >;

has 'repository' => (
    is       => 'ro',
    does     => 'PONAPI::DAO::Repository',
    required => 1,
);

sub retrieve_all {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id   and $doc->raise_error({ message => "retrieve_all: 'id' param not allowed" });
    $req->data and $doc->raise_error({ message => "retrieve_all: request body not allowed" });

    $doc->has_errors or
        eval {
            $doc->convert_to_collection;
            $repo->retrieve_all(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub retrieve {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id   or  $doc->raise_error({ message => "retrieve: 'id' param is missing" });
    $req->data and $doc->raise_error({ message => "retrieve: request body not allowed" });

    $doc->has_errors or
        eval {
            $repo->retrieve(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub retrieve_relationships {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id       or  $doc->raise_error({ message => "retrieve_relationships: 'id' param is missing" });
    $req->rel_type or  $doc->raise_error({ message => "retrieve_relationships: 'rel_type' param is missing" });
    $req->data     and $doc->raise_error({ message => "retrieve_relationships: request body not allowed" });

    $doc->has_errors or
        eval {
            $repo->retrieve_relationships(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub retrieve_by_relationship {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id       or  $doc->raise_error({ message => "retrieve_by_relationship: 'id' param is missing" });
    $req->rel_type or  $doc->raise_error({ message => "retrieve_by_relationship: 'rel_type' param is missing" });
    $req->data     and $doc->raise_error({ message => "retrieve_by_relationship: request body not allowed" });

    $doc->has_errors or
        eval {
            $repo->retrieve_by_relationship(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub create {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    # client-generated id needs to be passed in the body
    $req->id       and $doc->raise_error({ message => "create: 'id' param is not allowed" });
    $req->rel_type and $doc->raise_error({ message => "create: 'rel_type' param not allowed" });
    $req->data     or  $doc->raise_error({ message => "create: request body is missing" });

    $doc->has_errors or
        eval {
            $repo->create(
                document => $doc,
                %{ $req },
            );
            $doc->add_meta(
                message => "successfully created the resource: "
                         . $req->type
                         . " => "
                         . encode_json( $req->data )
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub create_relationships {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id       or $doc->raise_error({ message => "create_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "create_relationships: 'rel_type' param is missing" });
    $req->data     or $doc->raise_error({ message => "create_relationships: request body is missing" });

    $doc->has_errors or
        eval {
            $repo->create_relationships(
                document => $doc,
                %{ $req },
            );
            $doc->add_meta(
                message => "successfully created the relationship /"
                         . $req->type
                         . "/"
                         . $req->id
                         . "/"
                         . $req->rel_type
                         . " => "
                         . encode_json( $req->data )
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub update {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id       or  $doc->raise_error({ message => "update: 'id' param is missing" });
    $req->rel_type and $doc->raise_error({ message => "update: 'rel_type' param not allowed" });
    $req->data     or  $doc->raise_error({ message => "update: request body is missing" });

    $doc->has_errors or
        eval {
            $repo->update(
                document => $doc,
                %{ $req },
            );
            $doc->add_meta(
                message => "successfully updated the resource /"
                         . $req->type
                         . "/"
                         . $req->id
                         . " => "
                         . encode_json( $req->data )
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub update_relationships {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id       or $doc->raise_error({ message => "update_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "update_relationships: 'rel_type' param is missing" });
    $req->data     or $doc->raise_error({ message => "update_relationships: request body is missing" });

    $doc->has_errors or
        eval {
            $repo->update_relationships(
                document => $doc,
                %{ $req },
            );
            $doc->add_meta(
                message => "successfully updated the relationship /"
                         . $req->type
                         . "/"
                         . $req->id
                         . "/"
                         . $req->rel_type
                         . " => "
                         . encode_json( $req->data )
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}

sub delete : method {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id       or  $doc->raise_error({ message => "delete: 'id' param is missing" });
    $req->rel_type and $doc->raise_error({ message => "delete: 'rel_type' param not allowed" });
    $req->data     and $doc->raise_error({ message => "delete: request body is not allowed" });

    $doc->has_errors or
        eval {
            $repo->delete(
                document => $doc,
                %{ $req },
            );
            $doc->add_meta(
                message => "successfully deleted the resource /"
                         . $req->type
                         . "/"
                         . $req->id
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };


    return _dao_response( $req, $doc );
}

sub delete_relationships {
    my $self = shift;

    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);
    _valid_types( $req, $doc, $repo ) or return ( $doc->status, [], $doc->build );

    $req->id       or $doc->raise_error({ message => "delete_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "delete_relationships: 'rel_type' param is missing" });
    $req->data     or $doc->raise_error({ message => "delete_relationships: request body is missing" });

    $doc->has_errors or
        eval {
            $repo->delete_relationships(
                document => $doc,
                %{ $req },
            );
            $doc->add_meta(
                message => "successfully deleted the relationship /"
                         . $req->type
                         . "/"
                         . $req->id
                         . "/"
                         . $req->rel_type
                         . " => "
                         . encode_json( $req->data )
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };

    return _dao_response( $req, $doc );
}


### ... internal

sub _prepare_req {
    my $self = shift;

    my $req  = PONAPI::DAO::Request->new(@_);
    my $doc  = PONAPI::Builder::Document->new();
    my $repo = $self->repository;

    return ( $req, $doc, $repo );
}

sub _dao_response {
    my ( $req, $doc, @headers ) = @_;

    if ( $doc->has_errors ) {
        $doc->set_status(400);
    }
    elsif ( $req->send_doc_self_link ) {
        $doc->add_self_link( $req->req_base )
    }

    return ( $doc->status, \@headers, $doc->build );
}

sub _valid_types {
    my ( $req, $doc, $repo ) = @_;

    # check type and relations
    $repo->has_type( $req->type )
        or return _error_not_found( $doc, "Type `" . $req->type . "` doesn't exist." );

    if ( $req->rel_type ) {
        $repo->has_type( $req->rel_type )
            or return _error_not_found( $doc, "Type `" . $req->rel_type . "` doesn't exist." );

        $repo->has_relationship( $req->type, $req->rel_type )
            or return _error_not_found( $doc, "Types `" . $req->type . "` and `" . $req->rel_type . "` are not related" );
    }

    for ( @{ $req->include } ) {
        $repo->has_relationship( $req->type, $_ )
            or return _error_not_found( $doc, "Types `" . $req->type . "` and `$_` are not related" );
    }

    return 1;
}

sub _error_not_found {
    my ( $doc, $message ) = @_;

    $doc->raise_error({ message => $message });
    $doc->set_status(404);

    return;
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
