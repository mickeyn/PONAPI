use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;

use PONAPI::Util::Params;

my $str = 'include=author&fields[articles]=title,body,author&fields[people]=name';

my $params = PONAPI::Util::Params::get_params($str);

cmp_deeply(
    $params,
    {
        include => { author => 1 },
        fields  => {
            articles => { author => 1, body => 1, title => 1 },
            people   => { name => 1 },
        },
    },
    "params ok"
);

1;
