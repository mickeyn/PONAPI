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

    _check_no_id   ( $req, $doc );
    _check_no_data ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub retrieve {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id      ( $req, $doc );
    _check_no_data ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub retrieve_relationships {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id       ( $req, $doc );
    _check_rel_type ( $req, $doc );
    _check_no_data  ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub retrieve_by_relationship {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id       ( $req, $doc );
    _check_rel_type ( $req, $doc );
    _check_no_data  ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub create {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    # client-generated id needs to be passed in the body
    _check_no_id();
    _check_no_rel_type();
    _check_data();

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub create_relationships {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id       ( $req, $doc );
    _check_rel_type ( $req, $doc );
    _check_data     ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub update {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id          ( $req, $doc );
    _check_no_rel_type ( $req, $doc );
    _check_data        ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub update_relationships {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id       ( $req, $doc );
    _check_rel_type ( $req, $doc );
    _check_data     ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}

sub delete : method {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id          ( $req, $doc );
    _check_no_rel_type ( $req, $doc );
    _check_no_data     ( $req, $doc );

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
            _failure($doc);
        };


    return _dao_response( $req, $doc );
}

sub delete_relationships {
    my $self = shift;
    my ( $req, $doc, $repo ) = $self->_prepare_req(@_);

    _check_id       ( $req, $doc );
    _check_rel_type ( $req, $doc );
    _check_data     ( $req, $doc );

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
            _failure($doc);
        };

    return _dao_response( $req, $doc );
}


### ... internal

sub _prepare_req {
    my $self = shift;

    my $req  = PONAPI::DAO::Request->new(@_);
    my $doc  = PONAPI::Builder::Document->new();
    my $repo = $self->repository;

    _validate_types( $req, $doc, $repo );

    return ( $req, $doc, $repo );
}

sub _dao_response {
    my ( $req, $doc, @headers ) = @_;

    $doc->add_self_link( $req->req_base )
        if $req->send_doc_self_link;

    return ( $doc->status, \@headers, $doc->build );
}

sub _validate_types {
    my ( $req, $doc, $repo ) = @_;
    my ( $type, $rel_type ) = @{$req}{qw< type rel_type >};

    # check type and relations
    $repo->has_type( $type )
        or $doc->raise_error( 404, { message => "Type `$type` doesn't exist." } );

    if ( $rel_type and !$repo->has_relationship( $type, $rel_type ) ) {
        $doc->raise_error( 404, { message => "Types `$type` and `$rel_type` are not related" } );
    }

    for ( @{ $req->include } ) {
        $repo->has_relationship( $type, $_ )
            or $doc->raise_error( 404, { message => "Types `$type` and `$_` are not related" } );
    }

    return;
}

sub _check_id          { $_[0]->id   or  _bad_request( $_[1], "`id` is missing"                 ) }
sub _check_no_id       { $_[0]->id   and _bad_request( $_[1], "`id` not allowed"                ) }
sub _check_rel_type    { $_[0]->id   or  _bad_request( $_[1], "`relationship type` is missing"  ) }
sub _check_no_rel_type { $_[0]->id   and _bad_request( $_[1], "`relationship type` not allowed" ) }
sub _check_data        { $_[0]->data or  _bad_request( $_[1], "request body is missing"         ) }
sub _check_no_data     { $_[0]->data and _bad_request( $_[1], "request body is not allowed"     ) }

sub _bad_request {
    $_[0]->raise_error( 400, { message => $_[1] } );
}

sub _failure {
    $_[0]->raise_error(500, { message => 'A fatal error has occured, please check server logs' } );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
