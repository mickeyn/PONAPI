package PONAPI::Role::HasIncluded;

use strict;
use warnings;

use Moose::Role;

use PONAPI::Resource::Builder;

# we expect errors to be consumed by any class consuming this one
with 'PONAPI::Role::HasErrors';

has _included => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    default   => sub { +[] },
    handles   => {
        has_included => 'count',
    },
);

sub add_included {
    my $self = shift;

    @_ % 2 == 0 or die "[__PACKAGE__] add_included: args must be a key/value pairs list\n";

    my %args = @_;

    my ( $type, $id, $relationships, $attributes ) =
        @args{qw< type id relationships attributes >};

    $type and $id
        or die "[__PACKAGE__] add_included: resource must have type and id\n";

    # can't have the same (type,id) pair more than once
    for ( @{ $self->_included } ) {
        $type eq $_->{type} and $id eq $_->{id}
            and die "[__PACKAGE__] add_included: type/id pair was already included\n";
    }

    my $builder = PONAPI::Resource::Builder->new( type => $type, id => $id );
    $relationships and $builder->add_relationships ( $relationships );
    $attributes    and $builder->add_attributes    ( $attributes    );

    if ( $builder->has_errors ) {
        $self->add_errors( $builder->get_errors );
    } else {
        push @{ $self->_included } => $builder->build;
    }

    return $self;
}

1;

__END__
