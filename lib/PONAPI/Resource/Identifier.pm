package PONAPI::Resource::Identifier;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - ResourceIdentifier

use strict;
use warnings;
use Moose;

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

