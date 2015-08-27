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
    isa     => 'Maybe[ArrayRef[PONAPI::Resource]]',
    deafult => undef,
);

has errors => (
    is      => 'ro',
    isa     => 'Maybe[PONAPI::Error]',
    default => undef,
);

has links => (
    is      => 'ro',
    isa     => 'Maybe[PONAPI::Links]',
    default => undef,
);

has included => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[PONAPI::Resource]]',
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


sub bundle {
    my $self = shift;
    my %ret;

    # TODO: document must have at least one of: data, errors, meta

    $ret{data} = defined $self->data
        ? ( $self->is_collection_req ? $self->data : $self->data->[0] )
        : ( $self->is_collection_req ? [] : undef );

    $self->errors   and $ret{errors}   = $self->errors;
    $self->links    and $ret{links}    = $self->links;
    $self->included and $ret{included} = $self->included;

    keys %{ $self->meta }    and $ret{meta}    = $self->meta;
    keys %{ $self->jsonapi } and $ret{jsonapi} = $self->jsonapi;

    # 'included' must not be present without 'data'
    $ret{data} or delete $ret{included};

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

