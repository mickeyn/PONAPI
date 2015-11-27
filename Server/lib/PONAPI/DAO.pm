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
=encoding UTF-8

=head1 NAME

PONAPI::DAO - Interface to a JSON API.

=head1 SYNOPSIS

    use PONAPI::DAO;
    my $dao = PONAPI::DAO->new( repository => $repository );

    my ($status, $doc) = $dao->retrieve( type => $type, id => $id );
    die "retrieve failed; status $status, $doc->{errors}[0]{message}"
        if $doc->{errors};

    use Data::Dumper;
    say Dumper($doc->{data});

    # Fetch all resources of this type
    $dao->retrieve_all( type => $type );

    # Fetch all the relationships of $rel_type for the requested resource
    $dao->retrieve_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
    );

    # Like the above, but fetches full resources instead of just relationships
    $dao->retrieve_by_relationship(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
    );

    # Create a new resource
    $dao->create(
        type => $type,
        data => {
            type          => $type,
            attributes    => { ... },
            relationships => { ... },
        }
    );

    # *Add* a new entry to the relationships between $type and $rel_type
    $dao->create_relationsips(
        type     => $type,
        rel_type => $rel_type,
        data => [
            { ... },
        ]
    );

    # Update the attributes and/or relationships of a resource
    $dao->update(
        type => $type,
        id   => $id,
        data => {
            type          => $type,
            id            => $id,
            attributes    => { ... },
            relationships => { ... },
        },
    );

    # Update the relationships of a given type for one resource
    $dao->update_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
        data     => $update_data,
    );

    # Delete a resource
    $dao->delete(
        type => $type,
        id   => $id,
    );

    # Delete the members from the relationship
    $dao->delete_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
        data     => [
            { ... }, ...
        ],
    );

=head1 DESCRIPTION

Data Access Object for the JSON API.  This sits in between a server
and a L<repository|"PONAPI::DAO::Repository">.

All public DAO methods will return a 3-item list of a status, headers,
and the response body; this can then be fed directly to a PSGI application:

If present, the C<data> key of the response will contain either a
resource, or an arrayref of resources.  Resources are represented as
plain hashrefs, and they B<must> include both a C<type> and C<id>; they
may also contain additional keys.  See L<http://jsonapi.org/format/#document-resource-objects>
for a more in-depth description.

=head1 METHODS

=head2 new

Create a new instance of PONAPI::DAO.

    my $DAO = PONAPI::DAO->new(
        repository => $repository,
    );

Where C<$repository> implements the L<PONAPI::DAO::Repository> role.

As expanded below in L</"Return value of update operations">, the JSON API specification requires some
update operations returning C<200 OK> to also do a C<retrieve> and include
it in the response.
By default, C<PONAPI::DAO> will simply turn those C<200 OK> into
C<202 Accepted>, avoiding the need to do the extra fetch.  If needed, the
full 200 responses can be re-enabled by passing
C<respond_to_updates_with_200 => 1,> to C<new>.

=head1 API METHODS

With the exception of C<create> and C<retrieve_all>, the type and id arguments are mandatory
for all operations.

=head2 retrieve

Retrieve a resource.  Returns both the status of the request and
the document to be encoded.

    my ( $status, $doc ) = $dao->retrieve( type => "articles", id => 1 );

    if ( $doc->{errors} ) {
        die "Welp! Got some errors: ", join "\n",
                map $_->{message}, @{ $doc->{errors} };
    }

    say $doc->{data}{attributes}{title};

This accepts several optional values:

=over 4

=item fields

Allows fetching only specific fields of the resource:

    # This will fetch the entire resource
    $dao->retrieve(type => "articles", id => 1);

    # This will only fetch the title attribute
    $dao->retrieve(
        type   => "articles",
        id     => 1,
        fields => { articles => [qw/ title /] },
    );

Note how the fields fetched are requested per attribute type.  This allows you to
request specific fields in resources fetched through C<include>.

=item include

Allows including related resources.

    # The response will contain a top-level 'include' key with the
    # article's author
    $dao->retrieve(type => "articles", id => 1, include => [qw/ author /]);

    # We can combine include with C<fields> to fetch just the author's name:
    my $response = $dao->retrieve(
        id      => 1,
        type    => "articles",
        include => [qw/ author /],
        fields  => { author => [qw/ name /] }
    );

These will show up in the document in the top-level "included" key.

=item page

Used to provide pagination information to the underlaying repository.
Each implementation may provide a different pagination strategy.

=item filter

Entirely implementation-specific.

=back

=head2 retrieve_all

As you might expect, this is similar to C<retrieve>.  The returned document
will contain an arrayref of resource, rather than a single resource.

Depending on the implementation, you may be able to combine this with
C<filter> to retrieve multiple specific resources in a single request.

C<retrieve_all> takes all the same optional arguments as C<retrieve>,
plus one of its own:

=over 1

=item sort

Sorting strategy for the request.  Implementation-specific.

=back

=head2 retrieve_relationships

This retrieves all relationships of C<$type>.  Will return either an
arrayref or a hashref, depending on whether the requested relationship is
one-to-one or one-to-many:

    # Retrieves all comments made for an article
    $doc = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
    );
    # articles-to-comments is one-to-many, so it returns an arrayref
    say scalar @{ $doc->{data} };

    $doc = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
    );
    # articles-to-author is one-to-one, so it returns a hashref
    say $doc->{data}{id};

Takes two optional arguments, C<filter> and C<page>; both are entirely
implementation specific.

=head2 retrieve_by_relationships

Like C<retrieve_relationships>, but fetches full resources, rather than
identifier objects.

    # One-to-many relationship, this returns an arrayref of resource hashrefs.
    $dao->retrieve_by_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
    );
    # Same as:
    $doc      = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
    );
    $comments = $dao->retrieve_all(
        type   => $doc->{data}{type},
        filter => { id => [ map $_->{id}, @{ $doc->{data} } ] },
    );

    # One-to-one relationship
    $doc = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
    );
    # Same as:
    $doc    = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
    );
    $author = $dao->retrieve(
        type => $doc->{data}{type},
        id   => $doc->{data}{id},
    );

Takes the same optional arguments as C<retrieve> and C<retrieve_all>, whichever is applicable.

=head2 delete

Deletes a resource.

    $dao->delete( type => "articles", id => 1 );

May or may not return a document with a top-level meta key.

=head2 create

Creates a resource.

    $dao->create(
        type => "articles",
        data => {
            type          => "articles",
            attributes    => { ... },
            relationships => { ... },
        },
    );

This is one of the few methods where the C<id> is optional.  If provided, the underlaying
implementation may choose to use it, instead of generating a new idea for the created resource.

If successful, the response will include both a C<Location> header specifying
where the new resource resides, and a document that includes the newly
created resource.

=head2 update

Updates a resource.  This can be used to either update the resource attributes,
or its relationships; for the latter, you may want to consider using C<update_relationships>,
C<create_relationships>, or C<delete_relationships> instead.

    # Change article's title
    $dao->update(
        type => "articles",
        id   => 1,
        data => {
            type       => "articles",
            id         => 1,
            attributes => { title => "Updated title!" },
        }
    );

    # Change the article's author
    $dao->update(
        type => "articles",
        id   => 1,
        data => {
            type          => "articles",
            id            => 1,
            relationships => {
                author => { type => "people", id => 99 },
            },
        },
    );

    # Switch the tags of the article to a new set of tags
    $dao->update(
        type => "articles",
        id   => 1,
        data => {
            type          => "articles",
            id            => 1,
            relationships => {
                tags => [
                    { type => "tag", id => 4 },
                    { type => "tag", id => 5 },
                ],
            },
        },
    );

Missing attributes or relationships will B<not> be modified.

=head3 Return value of update operations

C<update>, C<delete_relationships>, C<create_relationships>, and
C<update_relationships> all follow the same rules for their responses.

If successful, they will return with either:

=over 3

=item 200 OK

If the update was successful and no extra data was updated, the response
will include a top-level C<meta> key, with a description of what was
updated.

Meanwhile, if the update was successful but more data than requested was
updated -- Consider C<updated-at> columns in a table -- then the request
will return both a top-level C<meta> key, and a top-level C<data> key,
containing the results of a C<retrieve> operation on the primary updated
resource.  Since this behavior can be undesirable, unless C<PONAPI::DAO->new>
was passed C<respond_to_updates_with_200 => 1>, this sort of response is
disabled, and the server will instead respond with a L</"202 Accepted">,
described below.

=item 202 Accepted

The response will include a top-level C<meta> key, with a human-readable
description of the success.

This is used when the server accepted the operation, but hasn't yet
completed it;  "Completed" being purposely very ambiguous.  In a SQL-based
implementation, it might simply mean that the change hasn't fully replicated
yet.

=item 204 No Content

If the operation was successful and nothing beyond the requested was modified,
the server may choose to send a 204 with no body, instead of a 200.

=back

=head2 delete_relationships

Remove members from a one-to-many relationship.

    # Remove two comments from the article
    $dao->delete(
        type     => "articles",
        id       => 1,
        rel_type => "comments',
        data     => [
            { type => "comment", id => 44 },
            { type => "comment", id => 89 },
        ],
    );

See also L</"Return value of update operations">.

=head2 update_relationships

Update the relationships of C<$rel_type>; this will replace all relationships
of the requested type with the ones provided.  Note that different semantics
are used for one-to-one and one-to-many relationships:

    # Replace all comments
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
        # articles-to-comments is one-to-many, so it gets an arrayref
        data     => [ { ... }, { ... } ],
    );

    # Change the author of the article
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
        # articles-to-authors is one-to-one, so it gets a simple hashref
        data     => { type => "people", id => 42 },
    );

    # Clear the comments of an article
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
        # Empty array to clear out a one-to-many
        data     => [],
    );

    # Clear the author of the relationship
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
        # undef to clear out one-to-one
        data     => undef,
    );

See also L</"Return value of update operations">.

=head2 create_relationships

Adds a new member to the specified one-to-many relationship.

    # Add a new, existing comment to the article
    $dao->create_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
        data     => [
            { type => "comment", id => 55 },
        ],
    );

See also L</"Return value of update operations">.

=cut

