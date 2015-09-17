package PONAPI::Links::Builder;

use strict;
use warnings;

use Moose;

with 'PONAPI::Role::HasErrors';

# use by Relationship, Document
has _self => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_self',
    writer    => '_set_self',
);

# used by Relationship
has _related => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_related',
    writer    => '_set_related',
);

# used by Document
has _pagination => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_pagination',
    writer    => '_set_pagination',
);

# used by Document
has _page => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_page',
    writer    => '_set_page',
);

sub _valid_link {
    my $value = shift;

    !ref $value
        and return 1;

    ref $value ne 'HASH'
        and return 0;

    exists $value->{href} and exists $value->{meta}
        or return 0;

    return 1;
}

sub add_self {
    my $self  = shift;
    my $value = shift;

    _valid_link( $value )
        or die "[__PACKAGE__] add_self: value should be a string or a hashref\n";

    $self->_set_self( $value );

    return $self;
}

sub add_related {
    my $self  = shift;
    my $value = shift;

    _valid_link( $value )
        or die "[__PACKAGE__] add_related: value should be a string or a hashref\n";

    $self->_set_related( $value );

    return $self;
}

sub add_pagination {
    my $self       = shift;
    my $pagination = shift;

    ref $pagination eq 'HASH'
        or die "[__PACKAGE__] add_pagination: should be a hashref\n";

    my %valid_field_names = map { $_ => 1 } qw< first last prev next >;

    for ( keys %{ $pagination } ) {
        exists $valid_field_names{$_}
            or die "[__PACKAGE__] add_pagination: invalid paginations field name: $_\n";
        _valid_link( $pagination->{$_} )
            or die "[__PACKAGE__] add_pagination: value should be a string or a hashref\n";
    }

    $self->_set_pagination( $pagination );

    return $self;
}

sub add_page {
    my $self  = shift;
    my $value = shift;

    ref $value and die "[__PACKAGE__] add_page: value should be a string\n";

    $self->_set_page( $value );

    return $self;
}

sub build {
    my $self = shift;
    my %ret;

    $self->has_self    and $ret{self}    = $self->_self;
    $self->has_related and $ret{related} = $self->_related;

    $self->has_pagination and
        @ret{ keys %{ $self->_pagination } } = values %{ $self->_pagination };

    return \%ret;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
