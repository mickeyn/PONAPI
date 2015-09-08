package PONAPI::Role::HasMeta;

use strict;
use warnings;

use Moose::Role;

has _meta => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        has_meta  => 'count',
        _set_meta => 'set',
    }
);

sub add_meta {
    my $self  = shift;

    my @args = ( @_ and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

    @args > 0 and @args % 2 == 0
        or die "[__PACKAGE__] add_meta: arguments list must be key/value pairs\n";

    $self->_set_meta( @args );

    return $self;
}


1;

__END__
