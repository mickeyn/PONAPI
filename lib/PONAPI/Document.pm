package PONAPI::Document;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Document

use strict;
use warnings;
use Moose;

has is_collection_req => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has data => (
    is      => 'ro',
    isa     => 'ArrayRef[Maybe[PONAPI::Resource]]',
    deafult => +[],
);

has errors => (
    is      => 'ro',
    isa     => 'Maybe[PONAPI::Error]',
    default => undef,
);

has meta => (
    is      => 'ro',
    isa     => 'HashRef',
    default => +{},
);

has jsonapi => (
    is      => 'ro',
    isa     => 'HashRef',
    default => +{},
);

has links => (
    is      => 'ro',
    isa     => 'PONAPI::Links',
    lazy    => 1,
    builder => '_build_links',
);

has included => (
    is      => 'ro',
    isa     => 'ArrayRef[PONAPI::Resource]',
    lazy    => 1,
    builder => '_build_included',
);


sub _build_links {}

sub _build_included {}

sub bundle {
    my $self = shift;
    my %ret;

    $ret{data} = $self->is_collection_req ? $self->data : $self->data->[0];

    return \%ret;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 data



=head2 erorrs



=head2 meta



=head2 jsonapi



=head2 links



=head2 included

