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

    if ( @_ > 0 and !$_[0] ) {
        push @{ $self->_data } => undef;
        return $self;
    }

    my %args;
    if ( @_ == 1 ) {
        ref $_[0] eq 'HASH' or die "[__PACKAGE__] add_data: single argument args can only be a HASH ref\n";
        %args = %{ $_[0] };
    }
    else {
        @_ % 2 == 0 or die "[__PACKAGE__] add_data: args must be a key/value pairs list\n";
        %args = @_;
    }

    my ( $type, $id, $relationships, $attributes ) =
        @args{qw< type id relationships attributes >};

    $type and $id
        or die "[__PACKAGE__] add_data: resource must have type and id\n";

    # can't have the same (type,id) pair more than once
    for ( @{ $self->_data } ) {
        $type eq $_->{type} and $id eq $_->{id}
            and die "[__PACKAGE__] add_data: type/id pair was already included\n";
    }

    require PONAPI::Resource::Builder; # lazy load this ....
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
