package PONAPI::Links::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Links

use strict;
use warnings;
use Moose;

has self => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_self',
);

has related => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_related',
);

has pagination => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_pagination',
);


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 self



=head2 related



=head2 pagination

