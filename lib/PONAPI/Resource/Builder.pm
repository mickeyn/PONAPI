package PONAPI::Resource::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Resource

use strict;
use warnings;
use Moose;

use PONAPI::Relationship::Builder;

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
    my %args = ( @_ == 1 and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

    keys %args or die "[__PACKAGE__] add_relationship: missing args\n";

    for my $k ( keys %args ) {
        my $v = $args{$k};
        ref $v eq 'HASH'
            or die "[__PACKAGE__] add_relationship: key $k: value must be a hashref\n";
        exists $v->{type}
            and die "[__PACKAGE__] add_relationship: type key is not allowed in relationships\n";
        exists $v->{id}
            and die "[__PACKAGE__] add_relationship: id key is not allowed in relationships\n";
        exists $self->_attributes->{$k}
            and die "[__PACKAGE__] add_relationship: relationship name $_ already exists in attributes\n";

        my $builder = PONAPI::Relationship::Builder->new();
        $v->{data}  and $builder->add_data( $v->{data} );
        $v->{meta}  and $builder->add_meta( $v->{meta} );
        $v->{links} and $builder->add_links( $v->{links} );

        if ( $builder->has_errors ) {
            $self->add_errors( $builder->get_errors );
        } else {
            $self->_relationships->{$k} = $builder->build;
        }
    }

    return $self;
}

sub add_attributes {
    my $self = shift;
    my %args = ( @_ == 1 and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

    keys %args or die "[__PACKAGE__] add_attributes: missing args\n";

    for my $k ( keys %args ) {
        my $v = $args{$k};

        $k eq 'type' and die "[__PACKAGE__] add_attributes: type key is not allowed in attributes\n";
        $k eq 'id'   and die "[__PACKAGE__] add_attributes: id key is not allowed in attributes\n";

        exists $self->_relationships->{$k}
            and die "[__PACKAGE__] add_attributes: attribute name $k already exists in relationships\n";

        ref $v eq 'HASH'
            or die "[__PACKAGE__] add_attributes: attribute value must be a hashref\n";
        exists $v->{relationships}
            and die "[__PACKAGE__] add_attributes: attribute value cannot contain relationships key\n";
        exists $v->{links}
            and die "[__PACKAGE__] add_attributes: attribute value cannot contain links key\n";

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

