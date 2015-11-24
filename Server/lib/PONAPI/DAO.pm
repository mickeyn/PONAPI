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
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );

    $req->id   and $doc->raise_error({ message => "retrieve_all: 'id' param not allowed" });
    $req->data and $doc->raise_error({ message => "retrieve_all: request body not allowed" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors ? $doc->set_status(400) : $doc->add_link_self( $req->req_base );
    return ( $doc->status, [], $doc->build );
}

sub retrieve {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id   or  $doc->raise_error({ message => "retrieve: 'id' param is missing" });
    $req->data and $doc->raise_error({ message => "retrieve: request body not allowed" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors ? $doc->set_status(400) : $doc->add_link_self( $req->req_base );
    return ( $doc->status, [], $doc->build );
}

sub retrieve_relationships {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "retrieve_relationships: 'id' param is missing" });
    $req->rel_type or  $doc->raise_error({ message => "retrieve_relationships: 'rel_type' param is missing" });
    $req->data     and $doc->raise_error({ message => "retrieve_relationships: request body not allowed" });

    # TODO:
    # add some (more) type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}

sub retrieve_by_relationship {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "retrieve_by_relationship: 'id' param is missing" });
    $req->rel_type or  $doc->raise_error({ message => "retrieve_by_relationship: 'rel_type' param is missing" });
    $req->data     and $doc->raise_error({ message => "retrieve_by_relationship: request body not allowed" });

    # TODO:
    # add some (more) type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}

sub create {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    # client-generated id needs to be passed in the body
    $req->id       and $doc->raise_error({ message => "create: 'id' param is not allowed" });
    $req->rel_type and $doc->raise_error({ message => "create: 'rel_type' param not allowed" });
    $req->data     or  $doc->raise_error({ message => "create: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}

sub create_relationships {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or $doc->raise_error({ message => "create_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "create_relationships: 'rel_type' param is missing" });
    $req->data     or $doc->raise_error({ message => "create_relationships: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
        eval {
            $self->repository->create_relationships(
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}

sub update {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "update: 'id' param is missing" });
    $req->rel_type and $doc->raise_error({ message => "update: 'rel_type' param not allowed" });
    $req->data     or  $doc->raise_error({ message => "update: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}

sub update_relationships {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or $doc->raise_error({ message => "update_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "update_relationships: 'rel_type' param is missing" });
    $req->data     or $doc->raise_error({ message => "update_relationships: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
        eval {
            $self->repository->update_relationships(
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}

sub delete : method {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or  $doc->raise_error({ message => "delete: 'id' param is missing" });
    $req->rel_type and $doc->raise_error({ message => "delete: 'rel_type' param not allowed" });
    $req->data     and $doc->raise_error({ message => "delete: request body is not allowed" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}

sub delete_relationships {
    my $self = shift;
    my $req  = PONAPI::DAO::Request->new(@_);

    my $doc = PONAPI::Builder::Document->new();

    $req->id       or $doc->raise_error({ message => "delete_relationships: 'id' param is missing" });
    $req->rel_type or $doc->raise_error({ message => "delete_relationships: 'rel_type' param is missing" });
    $req->data     or $doc->raise_error({ message => "delete_relationships: request body is missing" });

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    $doc->has_errors or
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

    $doc->has_errors and $doc->set_status(400);
    return ( $doc->status, [], $doc->build );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__