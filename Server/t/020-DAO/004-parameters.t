#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('PONAPI::DAO');
    use_ok('Test::PONAPI::DAO::Repository::MockDB');
    use_ok('Test::PONAPI::DAO::Repository::MockDB::Loader');
}

my $repository = Test::PONAPI::DAO::Repository::MockDB->new;
isa_ok($repository, 'Test::PONAPI::DAO::Repository::MockDB');

my $dao = PONAPI::DAO->new( version => '1.0', repository => $repository );
isa_ok($dao, 'PONAPI::DAO');

my %TYPE_ID = ( type => 'articles', id => 2 );

subtest '... fields' => sub {

    subtest '... fields set for type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, fields => { articles => [qw<title body>] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        ok(ref $data eq 'HASH', '... the document has one resource');

        ok($data->{attributes}, '... the `data` has an `attributes` key');
        is_deeply(
            [ sort keys %{ $data->{attributes} } ],
            [qw<body title>],
            '... `data.attributes` got only the requested fields'
        );

    };

    subtest '... empty fields set for type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, fields => { articles => [] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        ok(ref $data eq 'HASH', '... the document has one resource');

        ok(!exists $data->{attributes}, "... the `data` doesn't have an `attributes` key");

    };

    subtest '... empty fields set for relationship type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, fields => { people => [] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        ok(ref $data eq 'HASH', '... the document has one resource');

        ok($data->{relationships}, '... the `data` has a `relationships` key');
        ok(exists $data->{relationships}{comments}, "... `data.relationships` has a `comments` key");
        ok(!exists $data->{relationships}{authors}, "... `data.relationships` doesn't have an `authors` key");

    };

    subtest '... fields set for an included type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, include => [qw<authors>], fields => { people => [qw<name age>] } );
        my $doc = $ret[2];

        my $included = $doc->{included};
        ok($included, '... the document has an `included` key');
        ok(ref($included) eq 'ARRAY', '... `included` is an array');
        ok(@{$included} == 1, '... `included` has one resource');
        ok(ref($included->[0]) eq 'HASH', '... included resource is an object');
        ok(exists $included->[0]{attributes}, '... included resource has an `attributes` key');
        ok(ref($included->[0]{attributes}) eq 'HASH', '... the `attributes` points to a hash');
        is_deeply(
            [ sort keys %{ $included->[0]{attributes} } ],
            [qw< age name >],
            '... the included resource has only the requested fields'
        );

    };

    subtest '... empty fields set for an included type' => sub {

        my @ret = $dao->retrieve( %TYPE_ID, include => [qw<authors>], fields => { people => [] } );
        my $doc = $ret[2];

        ok(!exists $doc->{included}, "... the document doesn't have an `included` key");

    };

};

subtest '... filter' => sub {

    subtest '... filter with no keys or values' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', filter => {} );
        my $doc = $ret[2];

        my $errors = $doc->{errors};
        ok($errors, '... the document has an `errors` key');
        ok(ref $errors eq 'ARRAY', "and it's an array-ref");
        is(@$errors, 1, '... we have one error');
        is_deeply(
            $errors->[0],
            {
                detail => "`filter` is missing values",
                status => 400
            },
            '... and it contains what we expected'
        );
    };

    subtest '... filter key with no values' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', filter => { id => [] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        ok(ref $data eq 'ARRAY', '... the document has multiple resources');
        is(@$data, 0, '... but is an empty list');
    };

    subtest '... filter for specific ids' => sub {

        my @ret = $dao->retrieve_all( type => 'articles', filter => { id => [3,2] } );
        my $doc = $ret[2];

        my $data = $doc->{data};
        ok($data, '... the document has a `data` key');
        ok(ref $data eq 'ARRAY', '... the document has multiple resources');
        is(@$data, 2, '... exactly 2 of them');
        is_deeply(
            [ sort { $a <=> $b } map { $_->{id} } @$data ],
            [ 2, 3 ],
            'and we have the correct ids'
        )

    };

};

subtest '... include' => sub {

    subtest '... include with no values' => sub {

        my @ret = $dao->retrieve( type => 'articles', id => 2, include => [] );
        my $doc = $ret[2];

        my $errors = $doc->{errors};
        ok($errors, '... the document has an `errors` key');
        ok(ref $errors eq 'ARRAY', "and it's an array-ref");
        is(@$errors, 1, '... we have one error');
        is_deeply(
            $errors->[0],
            {
                detail => "`include` is missing values",
                status => 400
            },
            '... and it contains what we expected'
        );
    };

    subtest '... filter for specific ids' => sub {

        my @ret = $dao->retrieve( type => 'articles', id => 2, include => [qw< comments >] );
        my $doc = $ret[2];

        my $included = $doc->{included};
        ok($included, '... the document has an `included` key');
        ok(ref $included eq 'ARRAY', '... `included` value is an array-ref ');
        is(@$included, 2, '... of exactly 2 elements');
        is_deeply(
            [ sort { $a <=> $b } map { $_->{id} } @$included ],
            [ 5, 12 ],
            'and we have the correct ids'
        )

    };


};

# TODO: sort
# TODO: page

done_testing;
