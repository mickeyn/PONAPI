package PONAPI::Links::Builder;

use strict;
use warnings;

use Moose;

has _self => (
    is        => 'rw',
    isa       => 'Str | HashRef' ,
    predicate => 'has_self',
	reader    => 'self',
);

has _related => (
    is        => 'rw',
    isa       => 'Str | HashRef',
    predicate => 'has_related',
	reader    => 'related',
);

has _pagination => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => 'has_pagination',
	reader    => 'pagination',
);

has _page => (
	is 		  => 'rw',
	isa       => 'Str',
	writer    => 'with_page',
	reader    => 'page',
);


sub add_self {
	my ($self, $value) = @_;

	$self->_self($value);
	return $self;
};

sub add_related {
	my ($self, $related) = @_;

	$self->_related($related);
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

	$self->_pagination($pagination);

	return $self;
};

sub with_page {
	my ($self, $page) = @_;

	$self->_page($page);
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

