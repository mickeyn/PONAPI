package PONAPI::Role::Meta;

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
        has_meta => 'count',
    }
);

sub add_meta {
    my $self  = shift;
    my @args = @_;

    @args > 0 and @args % 2 == 0
        or die "[__PACKAGE__] add_meta: arguments list must be key/value pairs";

    while ( @args ) {
        my ($k, $v) = (shift @args, shift @args);
        $self->_meta->{$k} = $v;
    }

    return $self;
}

1;

__END__
