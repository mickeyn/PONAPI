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


=pod

TODO:{
    local $TODO = "... update to the new API";

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

}

=cut

done_testing;
