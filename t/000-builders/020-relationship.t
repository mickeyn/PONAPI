#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Relationship');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );
    isa_ok($b, 'PONAPI::Builder::Relationship');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');

    isa_ok($b->resource_id_builder, 'PONAPI::Builder::Resource::Identifier');
    does_ok($b->resource_id_builder, 'PONAPI::Builder');

    is($b->resource_id_builder->id, 10, '... got the ID we expected');
    is($b->resource_id_builder->type, 'foo', '... got the type we expected');

    can_ok( $b, $_ ) foreach qw[
        resource_id_builder

        links_builder
        add_link
        add_links

        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Builder::Relationship->new },
        qr/^Attribute \(.+\) does not pass the type constraint /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Relationship->new( id => '1' ) },
        qr/^Attribute \(type\) does not pass the type constraint /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Builder::Relationship->new( type => 'articles' ) },
        qr/^Attribute \(id\) does not pass the type constraint /,
        '... got the error we expected'
    );

};

subtest '... testing links sub-building' => sub {
    my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );
    isa_ok($b, 'PONAPI::Builder::Relationship');
    does_ok($b, 'PONAPI::Builder');
    does_ok($b, 'PONAPI::Builder::Role::HasLinksBuilder');

    ok(!$b->has_links, "new relationship should not have links");

    $b->add_links(
        related => "/related/2",
        self    => "/self/1",
    );

    ok($b->has_links, "relationship should now have links");

    is_deeply(
        $b->build,
        {
            data  => { id => 10, type => 'foo' },
            links => {
                self    => "/self/1",
                related => "/related/2",
            }
        },
        '... Relationship with links',
    );
};

=pod

TODO:{
    local $TODO = "... update to the new API";


    subtest '... testing relationship with meta' => sub {
        my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

        ok(!$b->has_meta, "new relationship shouldn't have meta");

        is(
            exception { $b->add_meta(info => "a meta info") },
            undef,
            '... got the (lack of) error we expected'
       	);

       	ok($b->has_meta, "relationship should have meta");

        is_deeply(
            $b->build,
            {
                meta => { info => "a meta info", }
            },
            '... Relationship with meta',
        );
    };

    subtest '... testing relationship with multiple meta' => sub {
        my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

        ok(!$b->has_meta, "new relationship shouldn't have meta");

        is(
            exception { $b->add_meta(info => "a meta info") },
            undef,
            '... got the (lack of) error we expected'
       	);

       	ok($b->has_meta, "relationship should have meta");

       	is(
            exception { $b->add_meta(physic => "a meta physic") },
            undef,
            '... got the (lack of) error we expected'
       	);

        is_deeply(
            $b->build,
            {
                meta => {
                	info => "a meta info",
                	physic => "a meta physic",
                }
            },
            '... Relationship with meta',
        );
    };

    subtest '... testing relationship with meta object' => sub {
        my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

        ok(!$b->has_meta, "new relationship shouldn't have meta");

        is(
            exception { $b->add_meta(
                foo => {
    	        	info => "a foo info",
    	        }
            )},
            undef,
            '... got the (lack of) error we expected'
       	);

       	ok($b->has_meta, "relationship should have meta");

        is_deeply(
            $b->build,
            {
            	meta => {
    	            foo => {
    		        	info => "a foo info",
    		        }
            	}
            },
            '... Relationship with meta object',
        );
    };

    subtest '... testing relationship with multiple data' => sub {
        my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

        $b->add_data({
            id => "1",
            type => "articles",
        });

        $b->add_data({
            id => "1",
            type => "nouns"
        });

        is_deeply(
            $b->build,
            {
                data =>
                [
                    {
                        id => "1",
                        type => "articles",
                    },
                    {
                        id => "1",
                        type => "nouns"
                    }
                ]
            },
            '... Relationship with multiple data',
        );
    };

    subtest '... testing build errors' => sub {

        subtest '... for empty Relationship' => sub {
            my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );
            is_deeply(
                $b->build,
                {
                    errors => [{
                        detail => 'Relationship should contain at least one of "links", "data" or "meta"',
                    }],
                },
                '... No empty Relationship',
            );
        };

        subtest '... links' => sub {
            my $b = PONAPI::Builder::Relationship->new( id => 10, type => 'foo' );

            like(
                exception { $b->add_links({
                    about => "/about/something",
                })},
                qr/invalid key: about/,
                '...about is an invalid key for the links object'
            );
        };
    };
}

=cut

done_testing;
