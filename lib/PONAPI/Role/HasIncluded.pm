package PONAPI::Role::HasIncluded;

use strict;
use warnings;

use Moose::Role;

has _included => (
    init_arg  => undef,
    is        => 'ro',
    writer    => '_set_included',
    predicate => 'has_included',
);

sub add_included {
    my $self     = shift;
    my $included = shift;

    $included and ref $included eq 'HASH'
        or die "[__PACKAGE__] add_included: invalid included\n";

    $self->_set_included( $included );

    return $self;
}

1;

__END__
