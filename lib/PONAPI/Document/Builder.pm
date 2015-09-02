package PONAPI::Document::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Document

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints qw[ enum ];

with qw<
    PONAPI::Role::HasData
    PONAPI::Role::HasMeta
    PONAPI::Role::HasLinks
    PONAPI::Role::HasErrors
    PONAPI::Role::HasIncluded
>;

# ...

has id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
);

has action => (
    is       => 'ro',
    isa      => enum([qw[ GET POST PATCH DELETE ]]),
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# ...

sub build {
    my $self = shift;

    # no errors -> must have data or meta
    unless ( $self->has_errors or $self->has_data or $self->has_meta ) {
        $self->add_errors( +{
            # ...
            detail => "Missing data/meta",
        } );
    }

    # errors -> return object with errors
    if ( $self->has_errors ) {
        return +{
            errors => $self->_errors,
        };
    }

    my %ret = ( jsonapi => { version => "1.0" } );

    if ( $self->has_data ) {
        $ret{data} = $self->has_id
            ? $self->_data->[0]
            : $self->_data;

        $self->has_include and $ret{included} = $self->_include;
    }

    $self->has_meta  and $ret{meta}  = $self->_meta;
    $self->has_links and $ret{links} = $self->_links;

    return \%ret;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

