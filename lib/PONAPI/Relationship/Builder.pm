package PONAPI::Relationship::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Relationships

use strict;
use warnings;
use Moose;

with qw<
    PONAPI::Role::HasData
    PONAPI::Role::HasMeta
    PONAPI::Role::HasLinks
    PONAPI::Role::HasErrors
>;

sub build {
    my $self = shift;
    my %ret;

    $self->has_data  and $ret{data}  = $self->_data;
    $self->has_meta  and $ret{meta}  = $self->_meta;

    $self->has_links or $self->has_data or $self->has_meta
        or $self->add_errors( +{
            detail => 'Relationship should contain at least one of "links", "data" or "meta"',
        });

    if ( $self->has_links ) {
        $self->_links->has_self or $self->_links->has_related
            or $self->add_errors( +{
                detail => 'Relationship links should contain at least one of "self" or "related"',
            });
        $ret{links} = $self->_links->build;
    }

    if ( $self->has_errors ) {
        return +{
            errors => $self->_errors,
        };
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



=head2 links



=head2 included
