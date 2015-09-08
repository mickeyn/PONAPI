package PONAPI::Role::HasData;

use strict;
use warnings;

use Moose::Role;

# we expect errors to be consumed by any class consuming this one
with 'PONAPI::Role::HasErrors';

has _data => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    default   => sub { +[] },
    handles   => {
        has_data => 'count',
    },
);

sub add_data {
    my $self = shift;
    my $args = shift;

    # allowed null value
    if ( !$args ) {
        push @{ $self->_data } => undef;
        return $self;
    }

    # build an object
    ref $args eq 'HASH'
        or die "[__PACKAGE__] add_data: value must be a hashref or undef\n";

    my ( $type, $id, $relationships, $attributes ) =
        @{$args}{qw< type id relationships attributes >};

    if ( $type and $id ) {
        my $builder = PONAPI::Resource::Builder->new( type => $type, $id => $id );
        $relationships and $builder->add_relationships ( $relationships );
        $attributes    and $builder->add_attributes    ( $attributes    );

        my $resource = $builder->build;

        if ( $builder->has_errors ) {
            $self->add_errors( $builder->get_errors );
        } else {
            push @{ $self->_data } => $resource;
        }
    }

    return $self;
}

1;

__END__
