package PONAPI::Links::Builder;

use strict;
use warnings;

use Moose;

has self => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_self',
    writer    => 'set_self',
);

has related => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_related',
    writer    => 'set_related',
);

has pagination => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_pagination',
    writer    => 'set_pagination',
);

has page => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_page',
    writer    => 'set_page',
);


sub add_self {
    my $self  = shift;
    my $value = shift;

    !ref($value) or ref $value eq 'HASH'
        or die '[__PACKAGE__] add_self: value should be a string or a hashref';

    $self->set_self( $value );

    return $self;
};

sub add_related {
    my $self  = shift;
    my $value = shift;

    !ref($value) or ref $value eq 'HASH'
        or die '[__PACKAGE__] add_related: value should be a string or a hashref';

    $self->set_related( $value );

    return $self;
};

sub add_pagination {
    my $self       = shift;
    my $pagination = shift;

    ref $pagination eq 'HASH'
        or die '[__PACKAGE__] add_pagination: should be a hashref';

    my %valid_field_names = (
        first => 1,
        last  => 1,
        prev  => 1,
        next  => 1,
    );

    my @invalid = grep +(!exists $valid_field_names{$_}), keys %{ $pagination };
    @invalid
        and die '[__PACKAGE__] add_pagination: Invalid paginations field names: ', (join ',', @invalid);

    $self->set_pagination( $pagination );

    return $self;
};

sub add_page {
    my $self  = shift;
    my $value = shift;

    !ref($value)
        or die '[__PACKAGE__] add_page: value should be a string';

    $self->set_page( $value );

    return $self;
};

sub build {
    my $self = shift;
    my %ret;

    $self->has_self    and $ret{self}    = $self->self;
    $self->has_related and $ret{related} = $self->related;

    $self->has_pagination and
        @ret{ keys %{ $self->pagination } } = values %{ $self->pagination };

    return \%ret;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 self



=head2 related



=head2 pagination
