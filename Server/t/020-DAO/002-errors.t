#!perl

use strict;
use warnings;

use Scalar::Util qw[ blessed ];

use Test::More;
use JSON::XS;

use PONAPI::DAO;
use Test::PONAPI::DAO::Repository::MockDB;
use Test::PONAPI::DAO::Repository::MockDB::Loader;

my $repository = Test::PONAPI::DAO::Repository::MockDB->new;
my $dao = PONAPI::DAO->new( version => '1.0', repository => $repository );


my @TEST_ARGS_BASE     = ( req_base => '/'        );
my @TEST_ARGS_TYPE     = ( type     => 'articles' );
my @TEST_ARGS_ID       = ( id       => 1          );
my @TEST_ARGS_HAS_BODY = ( has_body => 1          );
my @TEST_ARGS_NO_BODY  = ( has_body => 0          );

my @TEST_ARGS_BASE_TYPE    = ( @TEST_ARGS_BASE, @TEST_ARGS_TYPE );
my @TEST_ARGS_TYPE_ID      = ( @TEST_ARGS_TYPE, @TEST_ARGS_ID );
my @TEST_ARGS_BASE_TYPE_ID = ( @TEST_ARGS_BASE, @TEST_ARGS_TYPE, @TEST_ARGS_ID );

my @TEST_ARGS_BASE_TYPE_NO_BODY    = ( @TEST_ARGS_BASE_TYPE,    @TEST_ARGS_NO_BODY );
my @TEST_ARGS_TYPE_ID_NO_BODY      = ( @TEST_ARGS_TYPE_ID,      @TEST_ARGS_NO_BODY );
my @TEST_ARGS_BASE_TYPE_ID_NO_BODY = ( @TEST_ARGS_BASE_TYPE_ID, @TEST_ARGS_NO_BODY );

my @TEST_ARGS_BASE_TYPE_HAS_BODY    = ( @TEST_ARGS_BASE_TYPE,    @TEST_ARGS_HAS_BODY );
my @TEST_ARGS_TYPE_ID_HAS_BODY      = ( @TEST_ARGS_TYPE_ID,      @TEST_ARGS_HAS_BODY );
my @TEST_ARGS_BASE_TYPE_ID_HAS_BODY = ( @TEST_ARGS_BASE_TYPE_ID, @TEST_ARGS_HAS_BODY );


my $ERR_ID_MISSING          = "`id` is missing for this request";
my $ERR_ID_NOT_ALLOWED      = "`id` is not allowed for this request";
my $ERR_BODY_MISSING        = "request body is missing";
my $ERR_DATA_MISSING        = "request body is missing `data`";
my $ERR_BODY_NOT_ALLOWED    = "request body is not allowed";
my $ERR_RELTYPE_MISSING     = "`relationship type` is missing for this request";
my $ERR_RELTYPE_NOT_ALLOWED = "`relationship type` is not allowed for this request";
my $ERR_PAGE_NOT_ALLOWED    = "`page` is not allowed for this request";

my $SERVER_ERROR = [ 500, [], {
    errors => [{
        detail => 'A fatal error has occured, please check server logs',
        status => 500
    }],
    jsonapi => { version => '1.0' }
}];

sub error_test {
    my ($ret, $expect, $desc) = @_;
    my ($status, $headers, $doc) = @$ret;

    my $errors = $doc->{errors};
    isa_ok( $errors, 'ARRAY' );
    is_deeply($headers, [], "... no location headers since it was an error");

    my $expect_is_re = ref($expect->{detail}) eq ref(qr//);

    my ($err) = grep {
        $expect_is_re
            ? $_->{detail} =~ $expect->{detail}
            : $_->{detail} eq $expect->{detail}
    } @$errors;
    my $test = $expect_is_re ? \&like : \&is;
    $test->( $err->{detail}, $expect->{detail}, $desc );
    is( $err->{status},  $expect->{status}, '... and it has the expected error code' );
}

subtest '... retrieve all' => sub {
    {
        local $@;
        my $e;
        eval { $dao->retrieve_all(); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (has_body) is required\E/, "dies without a has_body" )
    }

    {
        local $@;
        my $e;
        eval { $dao->retrieve_all( @TEST_ARGS_NO_BODY ); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (req_base) is required\E/, "dies without a req_base" )
    }

    {
        local $@;
        my $e;
        eval { $dao->retrieve_all( @TEST_ARGS_BASE, @TEST_ARGS_NO_BODY ); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (type) is required\E/, "dies without a type" )
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY ],
            $ERR_ID_NOT_ALLOWED,
            "id is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_HAS_BODY, data => { id => 1 } ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY, include => [qw/author/] ],
            "Types `articles` and `author` are not related",
            "include with unknown types are caught",
            404
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status) = @$tuple;
        my @ret = $dao->retrieve_all(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => $expected_status||400 },
            "..."
        );
    }
};


subtest '... retrieve' => sub {
    {
        local $@;
        my $e;
        eval { $dao->retrieve_all(); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (has_body) is required\E/, "dies without a has_body" )
    }

    {
        local $@;
        my $e;
        eval { $dao->retrieve( @TEST_ARGS_NO_BODY ); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (req_base) is required\E/, "dies without a req_base" )
    }

    {
        local $@;
        my $e;
        eval { $dao->retrieve( @TEST_ARGS_BASE, @TEST_ARGS_NO_BODY ); 1; } or do { $e = "$@"; };
        like( $e, qr/\QAttribute (type) is required\E/, "dies without a type" )
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY ],
            $ERR_ID_MISSING,
            "id is required (missing)"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_HAS_BODY, data => { id => 1 } ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
      )
    {
        my ( $args, $expected_detail, $desc ) = @$tuple;
        my @ret = $dao->retrieve(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => 400 },
            "errors come back as 400s + empty extra headers"
        );
    }

    # Spec says we can either stop processing as soon as we spot an error, or keep going an accumulate·
    # multiple errors.  Currently we do multiple, so testing that here.
    my $ret = $dao->retrieve( @TEST_ARGS_BASE_TYPE_HAS_BODY, data => { id => 1 } );
    is_deeply(
        [ sort { $a->{detail} cmp $b->{detail} } @{ $ret->{errors} } ],
        [
            { detail => $ERR_ID_MISSING,       status => 400 },
            { detail => $ERR_BODY_NOT_ALLOWED, status => 400 },
        ],
        "DAO can result multiple error objects for one request",
    );

    # Retrieve with nonexistent stuff
    foreach my $tuple (
        [
            { include => [qw/nope/],          },
            { detail => "Types `people` and `nope` are not related", status => 404, },
        ],
        [
            { fields => { nope => ['nope'] },   },
            { detail => "Type `nope` doesn\'t exist.", status => 404, },
        ],
        [
            { fields => { people => ['nope'] }, },
            { detail => "Type `people` does not have at least one of the requested fields", status => 400, },
        ],
    )
    {
        my ($args, $expect) = @$tuple;
        my @ret = $dao->retrieve( @TEST_ARGS_BASE_TYPE_NO_BODY, type => 'people', id => 42, %$args );
        error_test(
            \@ret,
            $expect,
            "... caught bad retrieve with ", encode_json($args),
        );
    }
};


subtest '... retrieve relationships' => sub {
    foreach my $tuple (

# TODO
#[ [ type => 'fake', id => 1 ], "type \'fake\' not allowed", "DAO itself doesn't give errors for nonexistent types" ],
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY ],
            $ERR_ID_MISSING,
            "id is required (missing)"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY ],
            $ERR_RELTYPE_MISSING,
            "rel_type is missing"
        ],
        [
            [
                @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
                rel_type => "comments",
                data     => { id => 1 }
            ],
            $ERR_BODY_NOT_ALLOWED,
            "body is not allowed"
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status ) = @$tuple;
        foreach my $method (qw/retrieve_by_relationship retrieve_relationships/) {
            my @ret = $dao->$method(@$args);
            error_test(
                \@ret,
                { detail => $expected_detail, status => $expected_status||400 },
                "$desc $method"
            );
        }
    }
};


subtest '... create' => sub {
    {
        my @res = $dao->create(
            @TEST_ARGS_BASE_TYPE_HAS_BODY,
            data => {},
        );
        my $expected = [
            400,
            [],
            {
                errors  => [
                    {
                        detail => 'request body is missing `data`',
                        status => 400
                    }
                ],
                jsonapi => { version => '1.0' }
            }
        ];
        is_deeply( \@res, $expected, 'create missing type in data' );
    }
    {
        my @res = $dao->create(
            @TEST_ARGS_BASE_TYPE_HAS_BODY,
            data => { type => "not_articles" },
        );
        my $expected = [
            409,
            [],
            {
                errors  => [
                    {
                        detail => 'conflict between the request type and the data type',
                        status => 409,
                    }
                ],
                jsonapi => { version => '1.0' }
            }
        ];
        is_deeply( \@res, $expected, 'create types conflict' );
    }

    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY ],
            $ERR_ID_NOT_ALLOWED,
            "id is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY, rel_type => 1 ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "bad rel_type"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY, rel_type => 'authors' ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY ],
            $ERR_BODY_MISSING,
            "body is missing"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_HAS_BODY ],
            $ERR_DATA_MISSING,
            "data is missing"
        ],

        # Spec says these two need to return 409
        [
            [ @TEST_ARGS_BASE_TYPE_HAS_BODY, data => { type => "" } ],
            "conflict between the request type and the data type",
            "data->{type} is missing",
            409
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_HAS_BODY, data => { type => "fake" } ],
            "conflict between the request type and the data type",
            "data->{type} is wrong",
            409
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status ) = @$tuple;
        my @ret = $dao->create(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => $expected_status || 400 },
            $desc,
        );
    }

    my %good_create = (
        @TEST_ARGS_BASE_TYPE_HAS_BODY,
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
            409 => qr/\A(?:DBD|SQL error: Table constraint failed:)/,
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
            400 => 'Type `articles` does not have at least one of the attributes in data',
            "... error on unknown attributes"
        ],
        [
            {
                data => {
                    relationships => {
                        authors => [
                            { type => people => id => 42 },
                            { type => people => id => 43 },
                        ]
                    }
                }
            },
            400 => 'Types `articles` and `authors` are one-to-one, but got multiple values',
            "... error on unknown relationships"
        ],
        [
            {
                data => {
                    relationships => {
                        nope => { type => people => id => 42 }
                    }
                }
            },
            404 => 'Types `articles` and `nope` are not related',
            "... error on unknown relationships"
        ],
        [
            {
                data => {
                    relationships =>
                      { authors => { type => comments => id => 5 } }
                }
            },
            400 => 'Bad request data: Data has type `comments`, but we were expecting `people`',
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
            @ret = $dao->create(%{ dclone $copy });
        }
        if ( ref($expected) ) {
            like( $ret[2]->{errors}[0]{detail}, $expected, $msg );
            like( $w, $expected, "... and the warning matches" );
        }
        else {
            is( $ret[2]->{errors}[0]{detail}, $expected, $msg );
            is( $w, '', "... with no warnings" );
        }
        is( $ret[0], $status, "... and with the expected status" );
    }

};


subtest '... update' => sub {
    # Update with a bad/missing id
    foreach my $id ( -99, 99, "bad" ) {
        my @ret = $dao->update(
            @TEST_ARGS_BASE_TYPE_HAS_BODY,
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
                meta    => { detail  => '' },
            }
        ];
        $ret[2]->{meta}{detail} = '';
        is_deeply(
            \@ret,
            $expected,
            "trying to update a non-existent attribute should give a 404 and a body explaining why"
        );
    }

    # Updating nonexistent attributes
    {
        my @ret = $dao->update(
            @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
            data => {
                @TEST_ARGS_TYPE_ID,
                attributes => { not_real_attr => "not there!" },
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
                            detail => 'Type `articles` does not have at least one of the attributes in data',
                            status => 400
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
            @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
            data => {
                @TEST_ARGS_TYPE_ID,
                relationships => { not_real_rel => { type => fake => id => 1 } },
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
                            detail => 'Types `articles` and `not_real_rel` are not related',
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
    my @first_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID_NO_BODY );
    my ( $w, @ret ) = ('');
    {
        local $SIG{__WARN__} = sub { $w .= shift };
        @ret = $dao->update(
            @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
            data => {
                @TEST_ARGS_TYPE_ID,
                attributes    => { title => "All good" },
                relationships => {
                    comments => [
                        # These two are comments of article 2
                        { type => comments => id => 5  },
                        { type => comments => id => 12 },
                    ],
                },
            },
        );
    }
    my @second_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID_NO_BODY );
    is_deeply(
        \@first_retrieve,
        \@second_retrieve,
        "... changes are rolled back"
    );
    is( $ret[0], 409, "... the update had the correct error status" );
    ok( exists $ret[2]->{errors}, "... and an errors member" );
    ok( $w,                       "... and we gave a perl warning, too" );
};

subtest '... delete' => sub {
    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY ],
            $ERR_ID_MISSING,
            "id is missing"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY, rel_type => 1 ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed",
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY, rel_type => 0 ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed (false rel_type value)",
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY, rel_type => "" ],
            $ERR_RELTYPE_NOT_ALLOWED,
            'rel_type is not allowed (not allowed rel_type "")',
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY, rel_type => "comments" ],
            $ERR_RELTYPE_NOT_ALLOWED,
            "rel_type is not allowed",
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_HAS_BODY, data => { type => "" } ],
            $ERR_BODY_NOT_ALLOWED,
            "data is not allowed"
        ],
      )
    {
        my ( $args, $expected, $desc, $status ) = @$tuple;
        my @ret = $dao->delete(@$args);
        error_test(
            \@ret,
            { detail => $expected, status => $status||400 },
            "... $desc",
        );
    }
};


subtest '... create_relationships' => sub {
    foreach my $tuple (
        [
            [ @TEST_ARGS_BASE_TYPE_NO_BODY ],
            $ERR_ID_MISSING,
            "... id is missing"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_NO_BODY, rel_type => 'comments' ],
            $ERR_BODY_MISSING,
            "... body is missing",
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_HAS_BODY, rel_type => 'comments' ],
            $ERR_DATA_MISSING,
            "... data is missing",
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_HAS_BODY, data => [] ],
            $ERR_RELTYPE_MISSING,
            "... rel_type is missing"
        ],
        [
            [ @TEST_ARGS_BASE_TYPE_ID_HAS_BODY, rel_type => 'authors', data => [{}] ],
            "Types `articles` and `authors` are one-to-one",
            "... bad relationship",
        ],
      )
    {
        my ( $args, $expected_detail, $desc, $expected_status ) = @$tuple;
        my @ret = $dao->create_relationships(@$args);
        error_test(
            \@ret,
            { detail => $expected_detail, status => $expected_status||400 },
            "$desc create_relationships"
        );
    }

    # A conflict should return a 409
    # Also testing the rollback here, which is entirely implementation
    # dependent, but mandated by the spec
    my @first_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID_NO_BODY );
    my $w   = '';
    my @ret = do {
        local $SIG{__WARN__} = sub { $w .= shift };
        $dao->create_relationships(
            @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
            rel_type => 'comments',
            data     => [
                { type => comments => id => 99 },

                # Second one belongs to article 2
                { type => comments => id => 12 },
            ],
        );
    };

    error_test(
        \@ret,
        { detail => qr/SQL error: Table constraint failed:/, status => 409 },
        "... no DBD error in detail as expected",
    );

    my @second_retrieve = $dao->retrieve( @TEST_ARGS_BASE_TYPE_ID_NO_BODY );
    is_deeply(
        \@first_retrieve,
        \@second_retrieve,
        "... and the changes are not applied"
    );

    @ret = $dao->create_relationships(
        @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
        rel_type => 'comments',
        data     => [ { type => fake => id => 99 }, ],
    );

    error_test(
        \@ret,
        { detail => 'Bad request data: Data has type `fake`, but we were expecting `comments`', status => 400 },
        "... discrepancies between the requested rel_type and the data are spotted",
    );
};


subtest '... delete_relationships' => sub {
    {
        # Trying to delete a non-existent relationship
        # should return a 204:
        # http://jsonapi.org/format/#crud-updating-relationship-responses-204
        my @ret = $dao->delete_relationships(
            @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
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
                        'detail' => 'modified nothing for /articles/1/comments => [{"id":99}]'
                    }
                }
            ],
            "... deleting a non-existent resource returns a 204"
        );
    }

    {
        # Trying to delete a one-to-one is invalid
        my @ret = $dao->delete_relationships(
            @TEST_ARGS_BASE_TYPE_ID_HAS_BODY,
            rel_type => 'authors',
            data     => [ { type => people => id => 42 }, ],
        );

        error_test(
            \@ret,
            { detail => 'Types `articles` and `authors` are one-to-one', status => 400 },
            "... can't delete_relationships on a one-to-one",
        );
    }

};

subtest '... illegal params' => sub {
    # Bad params for request.
    my %all_args = (
        id       => { expected_detail => $ERR_ID_NOT_ALLOWED,      id => 1 },
        rel_type => { expected_detail => $ERR_RELTYPE_NOT_ALLOWED, rel_type => 'comments' },
        data     => { expected_detail => $ERR_BODY_NOT_ALLOWED,    data => { type => articles => id => 1 }, has_body => 1 },
        page     => { expected_detail => $ERR_PAGE_NOT_ALLOWED,    page => {} },
        fields   => { fields => { articles => [qw/title/] } },
        include  => { include => [ qw/comments/ ] },
    );

    my %request = (
        retrieve_all => {
            args    => \@TEST_ARGS_BASE_TYPE_NO_BODY,
            allowed => [qw/ page include fields /],
        },
        retrieve     => {
            args    => \@TEST_ARGS_BASE_TYPE_ID_NO_BODY,
            allowed => [qw/ include fields id /],
        },
        retrieve_relationships => {
            args    => [@TEST_ARGS_BASE_TYPE_ID_NO_BODY, rel_type => 'authors'],
            allowed => [qw/ page include fields id rel_type /],
        },
        retrieve_by_relationship => {
            args    => [@TEST_ARGS_BASE_TYPE_ID_NO_BODY, rel_type => 'authors'],
            allowed => [qw/ page include fields id rel_type /],
        },

        create => {
            args    => [ @TEST_ARGS_BASE_TYPE_HAS_BODY, data => {
                @TEST_ARGS_BASE_TYPE, attributes => { title => "woah" },
            } ],
            allowed => [qw/ id data /],
        },

        delete => {
            args    => \@TEST_ARGS_BASE_TYPE_ID_NO_BODY,
            allowed => [qw/ id /],
        },

        update => {
            args    => [ @TEST_ARGS_BASE_TYPE_ID_HAS_BODY, data => { @TEST_ARGS_BASE_TYPE_ID, attributes => { title => "foobar" } } ],
            allowed => [qw/ id data /],
        },
        update_relationships => {
            args    => [@TEST_ARGS_BASE_TYPE_ID_HAS_BODY, rel_type => 'comments', data => [{ type => 'comments', id => 5555 }]],
            allowed => [qw/ id rel_type data /],
        },
        delete_relationships => {
            args    => [@TEST_ARGS_BASE_TYPE_ID_HAS_BODY, rel_type => 'comments', data => [{ type => 'comments', id => 5555 }]],
            allowed => [qw/ id rel_type data /],
        },
        create_relationships => {
            args    => [@TEST_ARGS_BASE_TYPE_ID_HAS_BODY, rel_type => 'comments', data => [{ type => 'comments', id => 5555 }]],
            allowed => [qw/ id rel_type data /],
        },
    );

    foreach my $action ( sort keys %request ) {
        my ($args, $allowed) = @{ $request{$action} }{qw/args allowed/};
        my %allowed = map +($_=>1), @$allowed;

        my $glob = do {
            no strict 'refs';
            \*{"Test::PONAPI::DAO::Repository::MockDB::${action}"};
        };

        {
            use PONAPI::DAO::Constants;
            no warnings 'redefine';
            local *$glob = sub {
                my ($self, %args) = @_;
                $args{document}->add_resource( type => 'comments', id => 1 );
                return PONAPI_UPDATED_NORMAL;
            };
            use warnings;

            my @base_ret = $dao->$action(@$args);
            cmp_ok($base_ret[0], '<', 300, "... without any changes, we get a successful $action");

            # Check that disallowed arguments give us graceful errors
            my @disallowed = grep !exists $allowed{$_}, sort keys %all_args;
            foreach my $disallowed_arg ( @disallowed ) {
                my $expected_detail = $all_args{$disallowed_arg}{expected_detail};
                my @ret = $dao->$action(@$args,
                    %{ $all_args{$disallowed_arg} },
                );
                error_test(
                    \@ret,
                    {
                        detail => $expected_detail || "`$disallowed_arg` is not allowed for this request",
                        status => 400,
                    },
                    "... catches $disallowed_arg being passed to $action",
                );
            }

            my $expected_re = qr/\A\QServer error, halp at\E/;
            my $w   = '';
            my @ret = do {
                no warnings 'redefine';
                local $SIG{__WARN__} = sub { $w .= shift };
                local *$glob = sub { die "Server error, halp" };
                $dao->$action(@$args);
            };
            is_deeply(
                \@ret,
                $SERVER_ERROR,
                "... expected PONAPI response for error on $action"
            );
            like( $w, $expected_re, "... expected perl error from $action" );

            # See that we catch people using PONAPI::DAO::Exception without
            # an exception type
            ($w, @ret) = ('');
            my $msg = "my great exception!";
            @ret = do {
                no warnings 'redefine';
                local $SIG{__WARN__} = sub { $w .= shift };
                local *$glob = sub {
                    PONAPI::DAO::Exception->throw(message => $msg)
                };
                $dao->$action(@$args);
            };
            is_deeply(
                \@ret,
                $SERVER_ERROR,
                "... we catch exceptions without types",
            );
            like($w, qr/\A\Q$msg\E/, "... and make them warn");

            # Let's also test that all the methods detect unknown types
            $w = '';
            my %modified_arguments = @{ dclone $args };
            $modified_arguments{type} = 'fake';
            my $data = $modified_arguments{data} || [];
            $data = [ $data ] if ref($data) ne 'ARRAY';
            $_->{type} = 'fake' for @$data;
            @ret = $dao->$action( %modified_arguments );
            error_test(
                \@ret,
                {
                    detail => 'Type `fake` doesn\'t exist.',
                    status => 404,
                },
                "... bad types in $action lead to a 404",
            );
            is( $w, '', "... and no warnings" );

            # Check that update-like operations have strict return values
            my %strict_return_values = map +($_=>1), qw/
                update create_relationships
                update_relationships delete_relationships
            /;
            next unless $strict_return_values{$action};
            ($w, @ret) = ('');
            {
                no warnings 'redefine';
                local $SIG{__WARN__} = sub { $w .= shift    };
                local *$glob         = sub { return -1111.5 };
                @ret = $dao->$action(@$args);
            }
            is_deeply(
                \@ret,
                $SERVER_ERROR,
                "... Bad ->$action implementations are detected"
            );
            like(
                $w,
                qr/\Qoperation returned an unexpected value\E/,
                "... and gives a normal warning, too"
            );

        }
    }
};

done_testing;
