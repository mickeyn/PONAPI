package PONAPI::JSONAPI::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - JSONAPI

use strict;
use warnings;
use Moose;

with qw<
    PONAPI::Role::HasMeta
>;

has version => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_version',
);


sub build {
    my $self = shift;
    my %ret;

    $self->has_meta and $ret{meta} = $self->_meta;

    $ret{version} = $self->has_version ? $self->version : "1.0";

    return \%ret;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 version



=head2 meta



