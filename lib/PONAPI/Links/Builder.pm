package PONAPI::Links::Builder;

use strict;
use warnings;

use Moose;

# used by Error
has _about => (
	init_arg  => undef,
	is        => 'ro',
	predicate => 'has_about',
	writer    => '_set_about',
);

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

sub add_about {
	my $self  = shift;
	my $value = shift;

	!ref($value) or ref $value eq 'HASH'
        or die '[__PACKAGE__] add_about: value should be a string or a hashref';

	$self->_set_about( $value );

	return $self;
};

sub add_self {
    my $self  = shift;
    my $value = shift;

    !ref($value) or ref $value eq 'HASH'
        or die '[__PACKAGE__] add_self: value should be a string or a hashref';

    $self->_set_self( $value );

    return $self;
};

sub add_related {
    my $self  = shift;
    my $value = shift;

    !ref($value) or ref $value eq 'HASH'
        or die '[__PACKAGE__] add_related: value should be a string or a hashref';

    $self->_set_related( $value );

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

    $self->_set_pagination( $pagination );

    return $self;
};

sub add_page {
    my $self  = shift;
    my $value = shift;

    !ref($value)
        or die '[__PACKAGE__] add_page: value should be a string';

    $self->_set_page( $value );

    return $self;
};

sub build {
    my $self = shift;
    my %ret;

    $self->has_self    and $ret{self}    = $self->_self;
    $self->has_related and $ret{related} = $self->_related;

    $self->has_pagination and
        @ret{ keys %{ $self->_pagination } } = values %{ $self->_pagination };

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
