package PONAPI::Resource;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Resource

use strict;
use warnings;
use Moose;

has id => (
    is       => ro,
    isa      => 'Str',
    required => 1,
);

has type => (
    is       => ro,
    isa      => 'Str',
    required => 1,
);

has attributes => (
    is       => ro,
    isa      => 'HashRef',
    default  => +{},
);

has relationships => (
    is       => ro,
    isa      => 'HashRef',
    default  => +{},
);

has links => (
    is       => ro,
    isa      => 'Maybe[PONAPI::Links]',
    default  => undef,
);

has meta => (
    is       => ro,
    isa      => 'HashRef',
    default  => +{},
);


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 id



=head2 type



=head2 attributes



=head2 relationships



=head2 links



=head2 meta

