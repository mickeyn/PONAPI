package PONAPI::Role::Links;

use strict;
use warnings;

use Moose::Role;

has _links => (
    init_arg  => undef,
    is        => 'ro',
    writer    => 'set_links',
    predicate => 'has_links',
);

sub add_links {
    my $self  = shift;
    my $links = shift;

    ref $links eq 'PONAPI::Relationship::Links::Builder'
        or die;

    $self->set_links($links);
    return $self;
};

1;

__END__