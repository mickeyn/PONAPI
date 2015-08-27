package PONAPI::Links::Pagination;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Pagination

use strict;
use warnings;
use Moose;

has first => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    default  => undef,
);

has last => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    default  => undef,
);

has prev => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    default  => undef,
);

has next => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    default  => undef,
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
