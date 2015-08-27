package PONAPI::Links::Pagination;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Pagination

use strict;
use warnings;
use Moose;

has first => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_first',
);

has last => (
    is       => 'ro',
    isa       => 'Str',
    predicate => 'has_last',
);

has prev => (
    is       => 'ro',
    isa       => 'Str',
    predicate => 'has_prev',
);

has next => (
    is       => 'ro',
    isa       => 'Str',
    predicate => 'has_next',
);


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 first



=head2 last



=head2 prev



=head2 next
