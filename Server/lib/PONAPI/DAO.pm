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
    my $req  = $self->_prepare_req(@_);
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
    my $req  = $self->_prepare_req(@_);
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
    my $req  = $self->_prepare_req(@_);
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
    my $req  = $self->_prepare_req(@_);
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
    my $req  = $self->_prepare_req(@_);
    my $doc  = $req->document;

    # client-generated id needs to be passed in the body
    _check_no_id       ($req);
    _check_no_rel_type ($req);
    _check_has_data    ($req);

    $doc->has_errors or
        eval {
            $self->repository->create( %{ $req } );
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
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub create_relationships {
    my $self = shift;
    my $req  = $self->_prepare_req(@_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_has_data     ($req);

    $doc->has_errors or
        eval {
            $self->repository->create_relationships( %{ $req } );
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
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub update {
    my $self = shift;
    my $req  = $self->_prepare_req(@_);
    my $doc  = $req->document;

    _check_has_id      ($req);
    _check_no_rel_type ($req);
    _check_has_data    ($req);

    $doc->has_errors or
        eval {
            $self->repository->update( %{ $req } );
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
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub update_relationships {
    my $self = shift;
    my $req  = $self->_prepare_req(@_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_has_data     ($req);

    $doc->has_errors or
        eval {
            $self->repository->update_relationships( %{ $req } );
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
            _server_failure($doc);
        };

    return _dao_response($req);
}

sub delete : method {
    my $self = shift;
    my $req  = $self->_prepare_req(@_);
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
    my $req  = $self->_prepare_req(@_);
    my $doc  = $req->document;

    _check_has_id       ($req);
    _check_has_rel_type ($req);
    _check_has_data     ($req);

    $doc->has_errors or
        eval {
            $self->repository->delete_relationships( %{ $req } );
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
            _server_failure($doc);
        };

    return _dao_response($req);
}


### ... internal

sub _prepare_req {
    my $self = shift;

    my $req = PONAPI::DAO::Request->new(@_);
    $self->_validate_types( $req );
    return $req;
}

sub _validate_types {
    my ( $self, $req ) = @_;
    my ( $type, $rel_type, $doc ) = @{$req}{qw< type rel_type document >};

    # check type and relations
    $self->repository->has_type( $type )
        or $doc->raise_error( 404, { message => "Type `$type` doesn't exist." } );

    if ( $rel_type and !$self->repository->has_relationship( $type, $rel_type ) ) {
        $doc->raise_error( 404, { message => "Types `$type` and `$rel_type` are not related" } );
    }

    for ( @{ $req->include } ) {
        $self->repository->has_relationship( $type, $_ )
            or $doc->raise_error( 404, { message => "Types `$type` and `$_` are not related" } );
    }

    return;
}

sub _check_has_id       { $_[0]->id       or  _bad_request( $_[0]->document, "`id` is missing"                 ) }
sub _check_no_id        { $_[0]->id       and _bad_request( $_[0]->document, "`id` not allowed"                ) }
sub _check_has_rel_type { $_[0]->rel_type or  _bad_request( $_[0]->document, "`relationship type` is missing"  ) }
sub _check_no_rel_type  { $_[0]->rel_type and _bad_request( $_[0]->document, "`relationship type` not allowed" ) }
sub _check_has_data     { $_[0]->data     or  _bad_request( $_[0]->document, "request body is missing"         ) }
sub _check_no_data      { $_[0]->data     and _bad_request( $_[0]->document, "request body is not allowed"     ) }

sub _bad_request {
    $_[0]->raise_error( 400, { message => $_[1] } );
}

sub _server_failure {
    $_[0]->raise_error(500, { message => 'A fatal error has occured, please check server logs' } );
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
