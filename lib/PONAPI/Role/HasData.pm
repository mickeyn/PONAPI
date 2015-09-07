package PONAPI::Role::HasData;

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
    },
);

sub add_data {
    my $self  = shift;
    my $value = shift;

    !$value or ref $value eq 'HASH'
        or die "[__PACKAGE__] add_data: value must be a hashref or undef\n";

    push @{ $self->_data } => $value;

    return $self;
}

1;

__END__
