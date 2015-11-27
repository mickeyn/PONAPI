# ABSTRACT: PONAPI::DAO
package PONAPI::DAO;
use Moose;

use PONAPI::DAO::Constants;
use PONAPI::DAO::Repository;
use PONAPI::DAO::Request;
use PONAPI::DAO::Request::RelationshipUpdate;
use PONAPI::DAO::Request::ResourceCollection;
use PONAPI::Builder::Document;

use JSON::XS qw< encode_json >;

has 'repository' => (
    is       => 'ro',
    does     => 'PONAPI::DAO::Repository',
    required => 1,
);

has 'respond_to_updates_with_200' => (
    is  => 'ro',
    isa => 'Bool',
);

sub retrieve_all {
    my $self = shift;
    my $req  = $self->_prepare_req(retrieve_all => @_);
    my $doc  = $req->document;

    _check_no_id   ($req);
    _check_no_data ($req);

    $doc->has_errors or
        eval {
            $doc->convert_to_collection;
            $self->repository->retrieve_all( %{ $req } );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub retrieve {
    my $self = shift;
    my $req  = $self->_prepare_req(retrieve => @_);
    my $doc  = $req->document;

    _check_has_id  ($req);
    _check_no_data ($req);

    $doc->has_errors or
        eval {
            $self->repository->retrieve( %{ $req } );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub retrieve_relationships {
    my $self = shift;
    my $req  = $self->_prepare_req(retrieve_relationships => @_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_no_data      ($req);

    $doc->has_errors or
        eval {
            $self->repository->retrieve_relationships( %{ $req } );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub retrieve_by_relationship {
    my $self = shift;
    my $req  = $self->_prepare_req(retrieve_by_relationship => @_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_no_data      ($req);

    $doc->has_errors or
        eval {
            $self->repository->retrieve_by_relationship( %{ $req } );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub create {
    my $self = shift;
    my $req  = $self->_prepare_req(create => @_);
    my $doc  = $req->document;

    # client-generated id needs to be passed in the body
    _check_no_id       ($req);
    _check_no_rel_type ($req);
    _check_has_data    ($req);

    _check_data_has_type($req)
        and _check_data_type_match($req);

    # http://jsonapi.org/format/#crud-creating-responses-409
    # We need to return a 409 if $data->{type} ne $req->type
    if ( !$doc->has_errors && ($req->data->{type}||'') ne $req->type ) {
        $doc->raise_error(409, { message => "create: conflict between the request type and the data type" });
    }

    $doc->has_errors or
        eval {
            my $ret = $self->repository->create( %{ $req } );

            if ( $doc->has_errors || $PONAPI_ERROR_RETURN{$ret} ) {
                $doc->set_status(409) if $ret == PONAPI_CONFLICT_ERROR;
                $doc->set_status(404) if $ret == PONAPI_UNKNOWN_RELATIONSHIP;
            }
            else {
                $doc->add_meta(
                    message => "successfully created the resource: "
                         . $req->type
                         . " => "
                         . encode_json( $req->data )
                );
            }
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    my @headers;
    if ( !$doc->has_errors ) {
        my $document = $doc->build;
        # TODO make less terrible
        push @headers, Location => "/$document->{data}{type}/$document->{data}{id}";
    }

    return _dao_response( $req, @headers );
}

sub create_relationships {
    my $self = shift;
    my $req  = $self->_prepare_req(create_relationships => @_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_has_data     ($req);

    $doc->has_errors or
        eval {
            my $ret = $self->repository->create_relationships( %{ $req } );

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
                             . $req->type
                             . "/"
                             . $req->id
                             . "/"
                             . $req->rel_type
                             . " => "
                             . encode_json( $req->data )
                );
            }
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub update {
    my $self = shift;
    my $req  = $self->_prepare_req(update => @_);
    my $doc  = $req->document;

    _check_has_id      ($req);
    _check_no_rel_type ($req);
    _check_has_data    ($req);

    my $type = $req->type;
    if ( !$doc->has_errors ) {
        my $data = $req->data;

        # http://jsonapi.org/format/#crud-updating-responses-409
        # A server MUST return 409 Conflict when processing a PATCH request in which the
        # resource object's type and id do not match the server's endpoint.
        if ( %$data && ( ($data->{id}||'') ne $req->id || ($data->{type}||'') ne $type ) ) {
            $doc->raise_error(409, { message => "update: conflict between the request type/id and the data type/id" });
        }
    }
    else {
        $doc->raise_error(400, { message => "update: request body is missing" });
    }

    $doc->has_errors or
        eval {
            my $ret = $self->repository->update(
                document => $doc,
                %{ $req },
            );

            if ( !exists $PONAPI_UPDATE_RETURN_VALUES{$ret} ) {
                die ref($self->repository), "->update returned an unexpected value";
            }

            if ( $PONAPI_ERROR_RETURN{$ret} ) {
                $doc->set_status(409) if $ret == PONAPI_CONFLICT_ERROR;
                $doc->set_status(404) if $ret == PONAPI_UNKNOWN_RELATIONSHIP;
                return 1; # return from eval
            }

            my $resource = "/"
                         . $req->type
                         . "/"
                         . $req->id
                         . " => "
                         . encode_json( $req->data );

            my $message = "successfully updated the resource $resource";
            if ( $ret == PONAPI_UPDATED_NOTHING ) {
                $doc->set_status(404);
                $message = "updated nothing for the resource $resource"
            }

            $doc->add_meta( message => $message );

            if ( !$doc->has_errors && !$doc->has_status ) {
                if ( $self->respond_to_updates_with_200 ) {
                    $doc->set_status(200);
                    return $self->repository->retrieve(
                        type => $type,
                        id   => $req->id,
                        document => $doc,
                    ) if $ret == PONAPI_UPDATED_EXTENDED;
                }
                else {
                    $doc->set_status(202);
                }
            }

            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub update_relationships {
    my $self = shift;
    my $req  = $self->_prepare_req(update_relationships => @_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_has_data     ($req);

    $doc->has_errors or
        eval {
            my $ret = $self->repository->update_relationships( %{ $req } );

            if ( !exists $PONAPI_UPDATE_RETURN_VALUES{$ret} ) {
                die ref($self->repository), "->update_relationships returned an unexpected value";
            }

            my $json = JSON::XS->new->allow_nonref->utf8;
            $doc->add_meta(
                message => "successfully updated the relationship /"
                         . $req->type
                         . "/"
                         . $req->id
                         . "/"
                         . $req->rel_type
                         . " => "
                         . $json->encode( $req->data )
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub delete : method {
    my $self = shift;
    my $req  = $self->_prepare_req(delete => @_);
    my $doc  = $req->document;

    _check_has_id      ($req);
    _check_no_rel_type ($req);
    _check_no_data     ($req);

    $doc->has_errors or
        eval {
            $self->repository->delete( %{ $req } );
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
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub delete_relationships {
    my $self = shift;
    my $req  = $self->_prepare_req(delete_relationships => @_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_has_data     ($req);

    $doc->has_errors or
        eval {
            my $ret = $self->repository->delete_relationships( %{ $req } );

            if ( !exists $PONAPI_UPDATE_RETURN_VALUES{$ret} ) {
                die ref($self->repository), "->delete_relationships returned an unexpected value";
            }

            my $resource = "/"
                         . $req->type
                         . "/"
                         . $req->id
                         . "/"
                         . $req->rel_type
                         . " => "
                         . encode_json( $req->data );
            my $message  = "successfully deleted the relationship $resource";

        # http://jsonapi.org/format/#crud-updating-relationship-responses-204
            if ( $ret == PONAPI_UPDATED_NOTHING ) {
                $doc->set_status(204);
                $message = "deleted nothing for the resource $resource"
            }

            $doc->add_meta( message => $message );

            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            _server_failure($doc);
        };

    return _dao_response($req);
}


### ... internal

# delete & create relationships *always* take an arrayref of resources,
# while update_relationships may get either a hashref, an arrayref, or
# even undef
my %resource_collection = map +($_=>1), qw/
    delete_relationships
    create_relationships
/;
sub _prepare_req {
    my ($self, $request_type, @args) = @_;

    my $req;
    
    if ( exists $resource_collection{$request_type} ) {
        $req = PONAPI::DAO::Request::ResourceCollection->new(@args)
    }
    elsif ( $request_type eq 'update_relationships' ) {
        $req = PONAPI::DAO::Request::RelationshipUpdate->new(@args)
    }
    else {
        $req = PONAPI::DAO::Request->new(@args);
    }
    $self->_validate_types( $request_type, $req );
    return $req;
}

# http://jsonapi.org/format/#crud-updating-responses-404
# http://jsonapi.org/format/#fetching-resources-responses-404
# There's nothing on *creating* a resource of an invalid type,
# but might as well for consistency.
my %only_one_to_many = map +($_=>1), qw/
    delete_relationships
    create_relationships
/;
sub _validate_types {
    my ( $self, $request_type, $req ) = @_;
    my ( $type, $rel_type, $doc ) = @{$req}{qw< type rel_type document >};

    my $repo = $self->repository;

    # check type and relations
    $repo->has_type( $type )
        or $doc->raise_error( 404, { message => "Type `$type` doesn't exist." } );

    if ( defined($rel_type) ) {
        if ( !$repo->has_relationship( $type, $rel_type ) ) {
            $doc->raise_error( 404, {
                message => "Types `$type` and `$rel_type` are not related"
            });
        }
        elsif ( $only_one_to_many{$request_type} ) {
            $doc->raise_error(400, {
                message => "Types `$type` and `$rel_type` are one-to-one, invalid $request_type"
            }) if !$repo->has_one_to_many_relationship($type, $rel_type);
        }
    }

    for ( @{ $req->include } ) {
        $repo->has_relationship( $type, $_ )
            or $doc->raise_error( 404, { message => "Types `$type` and `$_` are not related" } );
    }

    return;
}

sub _check_has_id       { defined($_[0]->id)       or  _bad_request( $_[0]->document, "`id` is missing"                 ) }
sub _check_no_id        { defined($_[0]->id)       and _bad_request( $_[0]->document, "`id` not allowed"                ) }
sub _check_has_rel_type { defined($_[0]->rel_type) or  _bad_request( $_[0]->document, "`relationship type` is missing"  ) }
sub _check_no_rel_type  { defined($_[0]->rel_type) and _bad_request( $_[0]->document, "`relationship type` not allowed" ) }
sub _check_has_data     { $_[0]->has_data or  _bad_request( $_[0]->document, "request body is missing"         ) }
sub _check_no_data      { $_[0]->has_data and _bad_request( $_[0]->document, "request body is not allowed"     ) }

sub _check_data_has_type {
    my $req = shift;
    $req->data and exists $req->data->{'type'}
        or return _bad_request( $req->document, "request body: `data` key is missing" );
    return 1;
}

sub _check_data_type_match {
    my $req = shift;
    $req->data and exists $req->data->{'type'} and $req->data->{'type'} eq $req->type
        or return $req->document->raise_error( 409, {
            message => "conflict between the request type and the data type"
        });
    return 1;
}

sub _bad_request {
    $_[0]->raise_error( 400, { message => $_[1] } );
    return;
}

sub _server_failure {
    $_[0]->raise_error(500, { message => 'A fatal error has occured, please check server logs' } );
    return;
}

sub _dao_response {
    my ( $req, @headers ) = @_;
    my $doc = $req->document;

    $doc->add_self_link( $req->req_base )
        if $req->send_doc_self_link;

    return ( $doc->status, \@headers, $doc->build );
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
