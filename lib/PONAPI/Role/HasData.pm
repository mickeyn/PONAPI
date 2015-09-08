package PONAPI::Role::HasData;

use strict;
use warnings;

use Moose::Role;

use PONAPI::Resource::Builder;

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

    if ( @_ > 0 and !$_[0] ) {
        push @{ $self->_data } => undef;
        return $self;
    }

    @_ % 2 == 0 or die "[__PACKAGE__] add_data: args must be a key/value pairs list";

    my %args = @_;

    my ( $type, $id, $relationships, $attributes ) =
        @args{qw< type id relationships attributes >};

    $type and $id
        or die "[__PACKAGE__] add_data: resource must have type and id\n";

    my $builder = PONAPI::Resource::Builder->new( type => $type, id => $id );
    $relationships and $builder->add_relationships ( $relationships );
    $attributes    and $builder->add_attributes    ( $attributes    );

    if ( $builder->has_errors ) {
        $self->add_errors( $builder->get_errors );
    } else {
        push @{ $self->_data } => $builder->build;
    }

    return $self;
}

1;

__END__
