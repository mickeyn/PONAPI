package PONAPI::Resource::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Resource

use strict;
use warnings;
use Moose;

with qw<
    PONAPI::Role::HasMeta
    PONAPI::Role::HasLinks
    PONAPI::Role::HasErrors
>;

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _relationships => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        has_relationships => 'count',
    }
);

has _attributes => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        has_attributes => 'count',
    }
);

sub add_relationships {
    my $self = shift;
    my $args = shift;

    $args and ref $args eq 'HASH'
        or die "[__PACKAGE__] add_relationship: args must be a hashref\n";

    for my $name ( keys %$args ) {
        my $builder = PONAPI::Relationship::Builder->new();
        $args->{data}  and $builder->add_data( $args->{data} );
        $args->{meta}  and $builder->add_meta( $args->{meta} );
        $args->{links} and $builder->add_links( $args->{links} );

        my $relation = $builder->build;

        if ( $relation->has_errors ) {
            $self->add_errors( $relation->get_errors );
        } else {
            $self->_relationships->{$name} = $relation;
        }
    }

    return $self;
}

sub add_attributes {
    my $self = shift;
    my @args = @_;

    @args > 0 and @args % 2 == 0
        or die "[__PACKAGE__] add_attributes: arguments list must have key/value pairs\n";

    while ( @args ) {
        my ($k, $v) = (shift @args, shift @args);
        ref $v eq 'HASH' and delete @{$v}{qw< relationships links >};
        $self->_attributes->{$k} = $v;
    }

    return $self;
}

sub build_identifier {
    my $self = shift;

    my %ret = (
        type => $self->type,
        id   => $self->id,
    );

    $self->has_meta and $ret{meta} = $self->_meta;

    return \%ret;
}

sub build {
    my $self = shift;

    my $ret = $self->build_identifier;

    $self->has_attributes    and $ret->{attributes}    = $self->_attributes;
    $self->has_relationships and $ret->{relationships} = $self->_relationships;
    $self->has_links         and $ret->{links}         = $self->_links;

    return $ret;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 id



=head2 type



=head2 attributes



=head2 relationships



=head2 links



=head2 meta

