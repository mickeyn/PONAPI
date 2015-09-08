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

    @_ > 0 or die "[__PACKAGE__] add_meta: no arguments\n";

    my %args =
        ( ref $_[0] eq 'HASH' ) ? %{ $_[0] } :
        ( @_ % 2 == 0 )         ? @_         :
        ();

    for my $k ( keys %args ) {
        my $v = $args{$k};

        ref $v eq 'HASH'
            or die "[__PACKAGE__] add_meta: value must be hashref\n";

        $self->_meta->{$k} = $v;
    }

    return $self;
}


1;

__END__
