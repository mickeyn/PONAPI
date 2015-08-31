#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Document::Builder');
}

=pod

TODO:

=cut

subtest '... w/data test' => sub {

    my $b = PONAPI::Document::Builder->new(
        action => 'GET', 
        type   => 'articles',
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    $b->add_data({ type => 'articles', id => '10' });

    my $doc; 
    is(exception { $doc = $b->build }, undef, '.... building did not die');
    is_deeply(
        $b->build,
        { 
            jsonapi => { version => "1.0" },
            data    => [{ type => 'articles', id => '10' }],
        },
        '.... got the build we expected'
    );

};


subtest '... w/data that is null test' => sub {

    # XXX:
    # I am not sure that this test is okay, 
    # we need to look into the spec and see
    # if we actually want to have a collection 
    # with nulls in it.
    # - SL

    my $b = PONAPI::Document::Builder->new(
        action => 'GET', 
        type   => 'articles',
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    $b->add_data(undef);

    my $doc; 
    is(exception { $doc = $b->build }, undef, '.... building did not die');
    is_deeply(
        $b->build,
        { 
            jsonapi => { version => "1.0" },
            data    => [undef],
        },
        '.... got the build we expected'
    );

};

subtest '... w/meta test' => sub {

    # XXX:
    # Should `data` be an empty array 
    # ref in this case?
    # - SL

    my $b = PONAPI::Document::Builder->new(
        action => 'GET', 
        type   => 'articles',
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    $b->add_meta( turtles => "all the way down" );

    my $doc; 
    is(exception { $doc = $b->build }, undef, '.... building did not die');
    is_deeply(
        $b->build,
        { 
            jsonapi => { version => "1.0" },
            meta    => { turtles => "all the way down" },
        },
        '.... got the build we expected'
    );

};

subtest '... w/data and w/meta test' => sub {

    my $b = PONAPI::Document::Builder->new(
        action => 'GET', 
        type   => 'articles',
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    $b->add_data({ type => 'articles', id => '10' });
    $b->add_meta( turtles => "all the way down" );

    my $doc; 
    is(exception { $doc = $b->build }, undef, '.... building did not die');
    is_deeply(
        $b->build,
        { 
            jsonapi => { version => "1.0" },
            meta    => { turtles => "all the way down" },
            data    => [{ type => 'articles', id => '10' }], 
        },
        '.... got the build we expected'
    );

};

subtest '... w/data that is null and w/meta test' => sub {

    # XXX:
    # Same as above, should we be storing 
    # the undef into the array ref.
    # - SL

    my $b = PONAPI::Document::Builder->new(
        action => 'GET', 
        type   => 'articles',
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    $b->add_data(undef);
    $b->add_meta( turtles => "all the way down" );

    my $doc; 
    is(exception { $doc = $b->build }, undef, '.... building did not die');
    is_deeply(
        $b->build,
        { 
            jsonapi => { version => "1.0" },
            meta    => { turtles => "all the way down" },
            data    => [undef],
        },
        '.... got the build we expected'
    );

};

subtest '... error test' => sub {

    my $b = PONAPI::Document::Builder->new(
        action => 'GET', 
        type   => 'articles',
    );
    isa_ok($b, 'PONAPI::Document::Builder');

    my $doc; 
    is(exception { $doc = $b->build }, undef, '.... building did not die');
    is_deeply(
        $b->build,
        { errors => [{ detail => 'Missing data/meta' }] },
        '.... got the build we expected'
    );

};


done_testing;