package PONAPI::Role::HasLinks;

use strict;
use warnings;

use Moose::Role;

has _links => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_links',
    writer    => '_set_links',
);

sub add_links {
    my $self  = shift;
    my $links = shift;

    ref $links eq 'PONAPI::Relationship::Links::Builder'
        or die;

    $self->_set_links( $links );

    return $self;
};

1;

__END__
