package PONAPI::Role::Data;

use strict;
use warnings;

use Moose::Role;

has _data => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    default   => sub { +[] },
    handles   => {
        has_data => 'count',
        add_data => 'push',
    },
);

1;

__END__
