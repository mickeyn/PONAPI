#!perl

use strict;
use warnings;

use Scalar::Util qw[ blessed ];

use Test::More;

use PONAPI::DAO;
use Test::PONAPI::DAO::Repository::MockDB;
use Test::PONAPI::DAO::Repository::MockDB::Loader;

my $repository = Test::PONAPI::DAO::Repository::MockDB->new;
my $dao = PONAPI::DAO->new( repository => $repository );


my @TEST_ARGS_BASE = ( req_base => '/'        );
my @TEST_ARGS_TYPE = ( type     => 'articles' );
my @TEST_ARGS_ID   = ( id       => 1          );

my @TEST_ARGS_BASE_TYPE    = ( @TEST_ARGS_BASE, @TEST_ARGS_TYPE );
my @TEST_ARGS_TYPE_ID      = ( @TEST_ARGS_TYPE, @TEST_ARGS_ID );
my @TEST_ARGS_BASE_TYPE_ID = ( @TEST_ARGS_BASE, @TEST_ARGS_TYPE, @TEST_ARGS_ID );


my $ERR_ID_MISSING          = "`id` is missing";
my $ERR_ID_NOT_ALLOWED      = "`id` not allowed";
my $ERR_BODY_MISSING        = "request body is missing";
my $ERR_BODY_NOT_ALLOWED    = "request body is not allowed";
my $ERR_RELTYPE_MISSING     = "`relationship type` is missing";
my $ERR_RELTYPE_NOT_ALLOWED = "`relationship type` not allowed";


subtest '... retrieve all' => sub {
    {
        local $@;
        my $e;
        eval { $dao->retrieve_all(); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (req_base) is required\E/, "dies without a req_base" )
    }

    {
        local $@;
        my $e;
        eval { $dao->retrieve_all( @TEST_ARGS_BASE ); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (type) is required\E/, "dies without a type" )
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE_ID ],
            $ERR_ID_NOT_ALLOWED,
            "id is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE, data => { id => 1 } ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE, include => [qw/author/] ],
            "Types `articles` and `author` are not related",
            "include with unknown types are caught",
            404
        ],
      )
    {
        my ( $args, $expected, $desc, $status ) = @$tuple;
        my @res = $dao->retrieve_all(@$args);
        my $doc = $res[2];
        $status ||= 400;
        is( $res[0], $status, "... $status on error" );
        is( $doc->{errors}[0]{message}, $expected, $desc );
        is( scalar( @{ $doc->{errors} } ), 1, "... and that's the only error" );
    }
};

subtest '... retrieve' => sub {
    {
        local $@;
        my $e;
        eval { $dao->retrieve(); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (req_base) is required\E/, "dies without a req_base" )
    }

    {
        local $@;
        my $e;
        eval { $dao->retrieve( @TEST_ARGS_BASE ); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (type) is required\E/, "dies without a type" )
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE ],
            $ERR_ID_MISSING,
            "id is required (missing)"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE, id => "" ],
            $ERR_ID_MISSING,
            "id is required (empty string)"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID, data => { id => 1 } ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
      )
    {
        my ( $args, $expected, $desc ) = @$tuple;
        my @ret = $dao->retrieve(@$args);
        my $doc = pop @ret;
        is_deeply(
            \@ret,
            [ 400, [] ],
            "errors come back as 400s + empty extra headers"
        );
        is( $doc->{errors}[0]{message}, $expected, $desc );
    }

# Spec says we can either stop processing as soon as we spot an error, or keep going an accumulate·
# multiple errors.  Currently we do multiple, so testing that here.
    my $doc = $dao->retrieve( @TEST_ARGS_BASE_TYPE, data => { id => 1 } );

    is_deeply(
        [ sort { $a->{message} cmp $b->{message} } @{ $doc->{errors} } ],
        [
            { message => $ERR_ID_MISSING       }, # TODO: should status be part of the error?
            { message => $ERR_BODY_NOT_ALLOWED }, # TODO: should status be part of the error?
        ],
        "DAO can result multiple error objects for one request",
    );
};

subtest '... retrieve relationships' => sub {
    foreach my $tuple (

# TODO
#[ [ type => 'fake', id => 1 ], "type \'fake\' not allowed", "DAO itself doesn't give errors for nonexistent types" ],
        [
            [ @TEST_ARGS_BASE_TYPE ],
            $ERR_ID_MISSING,
            "id is required (missing)"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE, id => "" ],
            $ERR_ID_MISSING,
            "id is required (empty string)"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID, data => { id => 1 } ],
            $ERR_RELTYPE_MISSING,
            "rel_type is missing"
        ],

        [
            [
                @TEST_ARGS_BASE_TYPE_ID,
                rel_type => "comments",
                data     => { id => 1 }
            ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
      )
    {
        my ( $args, $expected, $desc ) = @$tuple;
        foreach my $method (qw/retrieve_by_relationship retrieve_relationships/) {
            my @ret = $dao->$method(@$args);
            my $doc = pop @ret;
            is_deeply(
                \@ret,
                [ 400, [] ],
                "errors come back as 400s + empty extra headers"
            );
            is(
                $doc->{errors}[0]{message},
                $expected,
                "$desc $method"
            );
        }
    }
};

subtest '... create' => sub {
    {
        my @res = $dao->create(
            @TEST_ARGS_BASE_TYPE,
            data => {},
        );
        my $expected = [
            400,
            [],
            {
                errors  => [ { message => 'request body: `data` key is missing' } ], # TODO: status?
                jsonapi => { version => '1.0' }
            }
        ];
        is_deeply( \@res, $expected, 'create missing type in data' );
    }

    {
        my @res = $dao->create(
            @TEST_ARGS_BASE_TYPE,
            data => { type => "not_articles" },
        );
        my $expected = [
            409,
            [],
            {
                errors  => [ { message => 'conflict between the request type and the data type' } ], # TODO: status?
                jsonapi => { version => '1.0' }
            }
        ];
        is_deeply( \@res, $expected, 'create types conflict' );
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE_ID ],
            $ERR_ID_NOT_ALLOWED,
            "id is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE, rel_type => 1 ],
            "Types `articles` and `1` are not related",
            "bad rel_type", 404
        ],
        [
            [ @TEST_ARGS_BASE_TYPE, rel_type => 'authors' ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE ],
            $ERR_BODY_MISSING,
            "data is missing"
        ],

        # Spec says these two need to return 409
        [
            [ @TEST_ARGS_BASE_TYPE, data => { type => "" } ],
            "conflict between the request type and the data type",
            "data->{type} is missing",
            409
        ],
        [
            [ @TEST_ARGS_BASE_TYPE, data => { type => "fake" } ],
            "conflict between the request type and the data type",
            "data->{type} is wrong",
            409
        ],
      )
    {
        my ( $args, $expected, $desc, $status ) = @$tuple;
        my @ret = $dao->create(@$args);
        my $doc = pop @ret;
        $status ||= 400;
        is_deeply(
            \@ret,
            [ $status || 400, [] ],
            "errors come back as $status + empty extra headers"
        );
        is( $doc->{errors}[0]{message}, $expected, $desc );
    }

    my %good_create = (
        @TEST_ARGS_BASE_TYPE,
        data     => {
            type => "articles",
            attributes => {
                title => "Title!",
                body  => "Body!",
            },
            relationships => {
                authors => { type => 'people', id => 42 },
            },
        }
    );

    use Storable qw/dclone/;
    foreach my $tuple (
        [
            { data => { attributes => {} } },
            400 => qr/\Qarticles.title may not be NULL\E/,
            "... error on bad create values"
        ],
        [
            {
                data => {
                    attributes => {
                        %{ $good_create{data}{attributes} },
                        extra => 111
                    }
                }
            },
            400 => 'Unknown columns passed to create',
            "... error on unknown attributes"
        ],
        [
            {
                data => {
                    relationships => {
                        nope => { type => people => id => 42 }
                    }
                }
            },
            404 => 'create_relationship: unknown relationship articles -> nope',
            "... error on unknown relationships"
        ],
        [
            {
                data => {
                    relationships =>
                      { authors => { type => comments => id => 5 } }
                }
            },
            409 => 'creating a relationship of type people, but data has type comments',
            "... error on relationship conflicts"
        ],
      )
    {
        my $copy = dclone( \%good_create );
        my ( $body, $status, $expected, $msg ) = @$tuple;

        while ( my ( $k, $v ) = each %$body ) {
            if ( ref($v) ) {
                while ( my ( $k2, $v2 ) = each %$v ) {
                    $copy->{$k}{$k2} = $v2;
                }
            }
            else {
                $copy->{$k} = $v;
            }
        }

        my ( $w, @ret ) = ('');
        {
            local $SIG{__WARN__} = sub { $w .= shift };
            @ret = $dao->create(%$copy);
        }
        if ( ref($expected) ) {
            like( $ret[2]->{errors}[0]{message}, $expected, $msg );
            like( $w, $expected, "... and the warning matches" );
        }
        else {
            is( $ret[2]->{errors}[0]{message}, $expected, $msg );
            is( $w, '', "... with no warnings" );
        }
        is( $ret[0], $status, "... and with the expected status" );
    }

};

subtest '... update' => sub {
    # Update with a bad/missing id
    foreach my $id ( -99, 99, "bad" ) {
        my @ret = $dao->update(
            @TEST_ARGS_BASE_TYPE,
            id => $id,
            data => {
                type => 'articles',
                id   => $id,
                attributes => { title => "Nonexistent" },
            },
        );
        my $expected = [
            404,
            [],
            {
                jsonapi => { version => '1.0' },
                meta    => { message => '' },
            }
        ];
        $ret[2]->{meta}{message} = '';
        is_deeply(
            \@ret,
            $expected,
            "trying to update a non-existent attribute should give a 404 and a body explaining why"
        );
    }

    # Updating nonexistent attributes
    {
        my @ret = $dao->update(
            @TEST_ARGS_BASE_TYPE_ID,
            data => {
                @TEST_ARGS_TYPE_ID,
                attributes => { not_real => "not there!" },
            },
        );
        is_deeply(
            \@ret,
            [
                400,
                [],
                {
                    errors => [
                        {
                            message => 'Unknown columns passed to update',
                            status  => 400
                        }
                    ],
                    jsonapi => { version => '1.0' }
                }
            ],
            "... 400 + error when updating an unknown attribute",
        );
    }

    # Updating nonexistent relationships
    {
        my @ret = $dao->update(
            @TEST_ARGS_BASE_TYPE_ID,
            data => {
                @TEST_ARGS_TYPE_ID,
                relationships => { not_real => { type => fake => id => 1 } },
            },
        );
        is_deeply(
            \@ret,
            [
                404,
                [],
                {
                    errors => [
                        {
                            message =>
'update: unknown relationship articles -> not_real',
                            status => 404
                        }
                    ],
                    jsonapi => { version => '1.0' }
                }
            ],
            "... 404 + error when updating an unknown relationship"
        );
    }

    # Update with a bad relationship; should roll back (imp. dependent)
    my @first_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID );
    my ( $w, @ret ) = ('');
    {
        local $SIG{__WARN__} = sub { $w .= shift };
        @ret = $dao->update(
            @TEST_ARGS_BASE_TYPE_ID,
            data => {
                @TEST_ARGS_TYPE_ID,
                attributes    => { title => "All good" },
                relationships => {
                    comments => [
                        # These two are comments of article 2
                        { type => comments => id => 5 },
                        { type => comments => id => 12 },
                    ],
                },
            },
        );
    }
    my @second_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID );
    is_deeply(
        \@first_retrieve,
        \@second_retrieve,
        "... changes are rolled back"
    );
    is( $ret[0], 400, "... the update had the correct error status" );
    ok( exists $ret[2]->{errors}, "... and an errors member" );
    ok( $w,                       "... and we gave a perl warning, too" );
};

subtest '... explodey repo errors' => sub {

    # See that we handle $repository exploding gracefully.
    my @all = (
        [ [qw/retrieve_all/]    => [ @TEST_ARGS_BASE_TYPE ] ],
        [ [qw/retrieve delete/] => [ @TEST_ARGS_BASE_TYPE_ID ] ],
        [ [qw/create/]          => [ @TEST_ARGS_BASE_TYPE, data => {qw/type articles/} ] ],
        [ [qw/update/]          => [ @TEST_ARGS_BASE_TYPE_ID, data => { @TEST_ARGS_BASE_TYPE } ] ],
        [ [qw/retrieve_by_relationship retrieve_relationships/] => [ @TEST_ARGS_BASE_TYPE_ID, rel_type => 'comments' ] ],
        [ [qw/create_relationships update_relationships delete_relationships/ ]
            => [ @TEST_ARGS_BASE_TYPE_ID, rel_type => comments => data => [ { 1 => 2 } ] ] ],
    );

    my %strict_return_values = map +($_=>1), qw/
        update create_relationships update_relationships delete_relationships
    /;

    my $expected_re = qr/\A\QServer error, halp at\E/;
    foreach my $tuple (@all) {
        my ( $methods, $arguments ) = @$tuple;
        foreach my $method (@$methods) {
            my $glob = do {
                no strict 'refs';
                \*{"Test::PONAPI::DAO::Repository::MockDB::$method"};
            };
            my $w   = '';
            my @ret = do {
                no warnings 'redefine';
                local $SIG{__WARN__} = sub { $w .= shift };
                local *$glob = sub { die "Server error, halp" };
                $dao->$method(@$arguments);
            };
            is_deeply(
                \@ret,
                [
                    400,
                    [],
                    {
                        errors => [
                            {
                                message =>
'A fatal error has occured, please check server logs',
                                status => 400
                            }
                        ],
                        jsonapi => { version => '1.0' }
                    }
                ],
                "... expected PONAPI response for error on $method"
            );
            like( $w, $expected_re, "... expected perl error from $method" );

            # Let's also test that all the methods detect unknown types
            $w = '';
            @ret = $dao->$method( @$arguments, type => 'fake' );
            is( $ret[0], 404, "... bad types in $method lead to a 404" );
            ok(
                scalar(
                    grep( $_->{message} eq 'Type `fake` doesn\'t exist.',
                        @{ $ret[2]->{errors} } )
                ),
                "... and returns an error document explaining why"
            );
            is( $w, '', "... and no warnings" );

            next unless $strict_return_values{$method};
            ($w, @ret) = ('');
            {
                no warnings 'redefine';
                local $SIG{__WARN__} = sub { $w .= shift };
                local *$glob = sub { return -1111.5 };
                @ret = $dao->$method(@$arguments);
            }
            is_deeply(
                \@ret,
                [
                    400,
                    [],
                    {
                        'errors' => [
                            {
                                'message' =>
    'A fatal error has occured, please check server logs',
                                'status' => 400
                            }
                        ],
                        'jsonapi' => { 'version' => '1.0' }
                    }
                ],
                "... Bad ->$method implementations are detected"
            );
            like(
                $w,
                qr/\Q->$method returned an unexpected value\E/,
                "... and gives a normal warning, too"
            );
        }
    }

};

subtest '... delete' => sub {
    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE ],
            "delete: 'id' param is missing",
            "id is missing"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID, rel_type => 1 ],
            "Types `articles` and `1` are not related",
            "rel_type is not allowed",
            404
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID, rel_type => "comments" ],
            "delete: 'rel_type' param not allowed",
            "rel_type is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID, data => { type => "" } ],
            "delete: request body is not allowed",
            "data is not allowed"
        ],
      )
    {
        my ( $args, $expected, $desc, $status ) = @$tuple;
        my @ret = $dao->delete(@$args);
        my $doc = pop @ret;
        $status ||= 400;
        is_deeply(
            \@ret,
            [ $status, [] ],
            "... errors come back as $status + empty extra headers"
        );
        is( $doc->{errors}[0]{message}, $expected, "... $desc" );
    }
};

subtest '... create_relationships' => sub {
    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE ],
            "create_relationships: 'id' param is missing",
            "... id is missing"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID ],
            "create_relationships: 'rel_type' param is missing",
            "... rel_type is missing"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID, rel_type => 'authors' ],
            "create_relationships: request body is missing",
            "... data is missing",
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID, rel_type => 'authors', data => [{}] ],
            "create_relationships: relationship articles -> authors is one-to-one, can't use create here",
            "... bad relationship",
        ],
      )
    {
        my ( $args, $expected, $desc, $status ) = @$tuple;
        my @res = $dao->create_relationships(@$args);
        my $doc = $res[2];
        $status ||= 400;
        is( $res[0],                    $status,   "... $status on error" );
        is( $doc->{errors}[0]{message}, $expected, $desc );
    }


    # A conflict should return a 409
    # Also testing the rollback here, which is entirely implementation
    # dependent, but mandated by the spec
    my @first_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID );
    my $w   = '';
    my @ret = do {
        local $SIG{__WARN__} = sub { $w .= shift };
        $dao->create_relationships(
            @TEST_ARGS_BASE_TYPE_ID,
            rel_type => 'comments',
            data     => [
                { type => comments => id => 99 },

                # Second one belongs to article 2
                { type => comments => id => 12 },
            ],
        );
    };

    my $msg = delete $ret[2]->{errors}[0]{message};
    is_deeply(
        \@ret,
        [
            409,
            [],
            {
                errors  => [         { status => 409 } ],
                jsonapi => { version => '1.0' }
            }
        ],
        "... relationship conflict returns a 409"
    );
    like(
        $msg,
        qr/DBD::SQLite::st execute failed: column id_comments is not unique/,
        "... (DBD error in message as expected)"
    );

    my @second_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID );
    is_deeply(
        \@first_retrieve,
        \@second_retrieve,
        "... and the changes are not applied"
    );

    @ret = $dao->create_relationships(
        @TEST_ARGS_BASE_TYPE_ID,
        rel_type => 'comments',
        data     => [ { type => fake => id => 99 }, ],
    );

    is_deeply(
        \@ret,
        [
            409,
            [],
            {
                errors => [
                    {
                        message =>
'creating a relationship of type comments, but data has type fake',
                        status => 409
                    }
                ],
                jsonapi => { version => '1.0' }
            }
        ],
"... discrepancies between the requested rel_type and the data are spotted",
    );

};

subtest '... delete_relationships' => sub {
    {
        # Trying to delete a non-existent relationship
        # should return a 204:
        # http://jsonapi.org/format/#crud-updating-relationship-responses-204
        my @ret = $dao->delete_relationships(
            @TEST_ARGS_BASE_TYPE_ID,
            rel_type => 'comments',
            data     => [ { type => comments => id => 99 }, ],
        );

        is_deeply(
            \@ret,
            [
                204,
                [],
                {
                    'jsonapi' => {
                        'version' => '1.0'
                    },
                    'meta' => {
                        'message' =>
'deleted nothing for the resource /articles/1/comments => [{"id":99}]'
                    }
                }
            ],
            "... deleting a non-existent resource returns a 204"
        );
    }

    {
        # Trying to delete a one-to-one is invalid
        my @ret = $dao->delete_relationships(
            @TEST_ARGS_BASE_TYPE_ID,
            rel_type => 'authors',
            data     => [ { type => people => id => 42 }, ],
        );

        is_deeply(
            \@ret,
            [
                400,
                [],
                {
                    'errors' => [
                        {
                            'status' => 400,
                            'message' =>
'delete_relationships: relationship articles -> authors is one-to-one, can\'t use delete here'
                        }
                    ],
                    'jsonapi' => {
                        'version' => '1.0'
                    }
                }
            ],
            "... can't delete_relationships on a one-to-one"
        );
    }

};

done_testing;
