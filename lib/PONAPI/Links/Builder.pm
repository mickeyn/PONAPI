package PONAPI::Links::Builder;

use strict;
use warnings;

use Moose;

has self => (
    is        => 'ro',
    isa       => 'Str | HashRef' ,
    predicate => 'has_self',
    writer    => 'set_self',
);

has related => (
    is        => 'ro',
    isa       => 'Str | HashRef',
    predicate => 'has_related',
    writer    => 'set_related',
);

has pagination => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_pagination',
    writer    => 'set_pagination',
);

has page => (
    is        => 'ro',
    isa       => 'Str',
    writer    => 'set_page',
);


sub add_self {
    my ($self, $value) = @_;

    $self->set_self($value);
    return $self;
};

sub add_related {
    my ($self, $related) = @_;

    $self->set_related($related);
    return $self;
};

sub add_pagination {
    my ($self, $pagination) = @_;

    ref $pagination eq 'HASH'
        or die 'Pagination should be a hashref';

    my %valid_field_names = (
        first => 1,
        last  => 1,
        prev  => 1,
        next  => 1,
    );

    my @invalid = grep +(!exists $valid_field_names{$_}), keys %{ $pagination };

    @invalid
        and die 'Invalid paginations field names: ', (join ',', @invalid);

    $self->set_pagination($pagination);

    return $self;
};

sub with_page {
    my ($self, $page) = @_;

    $self->set_page($page);
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
