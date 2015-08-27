package PONAPI::Links;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Links

use strict;
use warnings;
use Moose;

has self => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => undef,
);

has related => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => undef,
);

has pagination => (
    is      => 'ro',
    isa     => 'Maybe[PONAPI::Links::Pagination]',
    default => undef,
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

