#!perl 

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Links::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Links::Builder->new;
    isa_ok($b, 'PONAPI::Links::Builder');
    
    can_ok( $_ ) foreach qw[
        add_self
        has_self

        add_related
        has_related

        add_pagination
        has_pagination

        with_page

        build
    ];

};

subtest '... test set, get back and build self' => sub {
    my $links = PONAPI::Links::Builder->new;
    isa_ok($b, 'PONAPI::Links::Builder');

    my $x = $links->add_self('/resource/1');

    isa_ok(
        $x,
        'PONAPI::Links::Builder', 
        '... our builder always returns an instance of a builder'
    );
    is($x, $links, '... and the instance is ourself');

    is($links->self, '/resource/1', '... we are getting self URL back');

    my ($result, $error) = $links->build;

    ok(not defined $error, '... no error found');
    is_deeply(
        $result,
        { self => '/resource/1' },
        '... got the build result as expected'
    );
};

subtest '... test set, get back and build multiple fields' => sub {
    my $links = PONAPI::Links::Builder->new;
    isa_ok($b, 'PONAPI::Links::Builder');

    is(
        exception {
            $links->add_self('/resource/1')
                  ->add_related('/resource/1/related/2')
                  ->add_pagination({
                        first => '/resources/1',
                        last  => '/resources/5',
                        next  => '/resources/4',
                        prev  => '/resources/2',
                   });
        }, undef,
        '... added self, related and pagination successfully'
    );

    is($links->self, '/resource/1', 'we are getting self back');
    is($links->related, '/resource/1/related/2', 'we are getting related back');
    is_deeply(
        $links->pagination, 
        {
            first   => '/resources/1',
            last    => '/resources/5',
            next    => '/resources/4',
            prev    => '/resources/2',
        },
        '.... got the pagination'
    );    

    my ($result, $error) = $links->build;

    ok(not defined $error, '... no error found');

    is_deeply(
        $result, 
        {
            self    => '/resource/1',
            related => '/resource/1/related/2',
            first   => '/resources/1',
            last    => '/resources/5',
            next    => '/resources/4',
            prev    => '/resources/2',
        },
        '.... built the result we expected'
    );

};

done_testing;