package PONAPI::Relationships::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Relationships

use strict;
use warnings;
use Moose;

has links => (
    is        => 'ro',
    isa       => 'PONAPI::Links',
    predicate => 'has_links',
);

has data => (
    is        => 'ro',
    isa       => 'ArrayRef[PONAPI::Resource]',
    predicate => 'has_data',
);

has _meta => (
    init_arg => undef,
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
    handles => {
        has_meta => 'count',
        add_meta => 'set',
        get_meta => 'get',
    }
);


sub build {
    my $self = shift;
    my %ret;

    $self->has_links and $ret{links} = $self->links;
    $self->has_data  and $ret{data}  = $self->data;
    $self->has_meta  and $ret{meta}  = $self->_meta;

    $self->has_links or $self->has_data or $self->has_meta
        or return undef;

    if ( $self->has_links ) {
        $self->links->has_self or $self->links->has_related
            or return undef;
    }

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

