package PONAPI::Util::Params;

use strict;
use warnings;

sub get_params {
    my $str = shift;
    my %ret;

    for ( split /\&/ => $str ) {
        /^include=(.+)/ and $ret{include} = +{ map { $_ => 1 } split /,/ => $1 };
        /^fields\[(.+)\]=(.+)/ and $ret{fields}{$1} = +{ map { $_ => 1 } split /,/ => $2 };
    }

    return \%ret;
}

1;
