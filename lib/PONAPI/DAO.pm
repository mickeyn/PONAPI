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


sub _validate_request_no_id {
    my ( $req, $doc ) = @_;
    $req->has_id or return 1; # no id
    $doc->raise_error({ message => "'id' param not allowed" });
    return 0;
}

sub _validate_request_no_data {
    my ( $req, $doc ) = @_;
    $req->has_data or return 1; # no id
    $doc->raise_error({ message => "request body not allowed" });
    return 0;
}

sub retrieve_all {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );

    $req->id       and $doc->raise_error({ message => "retrieve_all: 'id' param not allowed" });
    $req->has_data and $doc->raise_error({ message => "retrieve_all: request body not allowed" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->retrieve_all(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };
    }

    return ( $doc->status, $doc->build );
}

sub retrieve {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "retrieve: 'id' param is missing" });
    $req->has_data and $doc->raise_error({ message => "retrieve: request body not allowed" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->retrieve(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE: this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };
    }

    return ( $doc->status, $doc->build );
}

sub retrieve_relationships {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "retrieve_relationships: 'id' param is missing" });
    $req->rel_type or  $doc->raise_error({ message => "retrieve_relationships: 'rel_type' param is missing" });
    $req->has_data and $doc->raise_error({ message => "retrieve_relationships: request body not allowed" });

    # TODO:
    # add some (more) type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->retrieve_relationships(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };
    }

    return ( $doc->status, $doc->build );
}

sub retrieve_by_relationship {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "retrieve_by_relationship: 'id' param is missing" });
    $req->rel_type or  $doc->raise_error({ message => "retrieve_by_relationship: 'rel_type' param is missing" });
    $req->has_data and $doc->raise_error({ message => "retrieve_by_relationship: request body not allowed" });

    # TODO:
    # add some (more) type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->retrieve_by_relationship(
                document => $doc,
                %{ $req },
            );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };
    }

    return ( $doc->status, $doc->build );
}

sub create {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    # client-generated id needs to be passed in the body
    $req->id       and $doc->raise_error({ message => "create: 'id' param is not allowed" });
    $req->rel_type and $doc->raise_error({ message => "create: 'rel_type' param not allowed" });
    $req->has_data or  $doc->raise_error({ message => "create: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->create(
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
    }

    return ( $doc->status, $doc->build );
}

sub create_relationships {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or $doc->raise_error({ message => "create_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "create_relationships: 'rel_type' param is missing" });
    $req->has_data or $doc->raise_error({ message => "create_relationships: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->delete_relationships(
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
    }

    return ( $doc->status, $doc->build );
}

sub update {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "update: 'id' param is missing" });
    $req->rel_type and $doc->raise_error({ message => "update: 'rel_type' param not allowed" });
    $req->has_data or  $doc->raise_error({ message => "update: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->update(
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
    }

    return ( $doc->status, $doc->build );
}

sub delete : method {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "delete: 'id' param is missing" });
    $req->rel_type and $doc->raise_error({ message => "delete: 'rel_type' param not allowed" });
    $req->has_data and $doc->raise_error({ message => "delete: request body is not allowed" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->delete(
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
    }

    return ( $doc->status, $doc->build );
}

sub delete_relationships {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or $doc->raise_error({ message => "delete_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "delete_relationships: 'rel_type' param is missing" });
    $req->has_data or $doc->raise_error({ message => "delete_relationships: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    if ( $doc->has_errors ) {
        $doc->set_status(400); # bad request
    }
    else {
        eval {
            $self->repository->delete_relationships(
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
    }

    return ( $doc->status, $doc->build );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
