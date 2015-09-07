package PONAPI::Role::HasLinks;

use strict;
use warnings;

use Moose::Role;

# we expect errors to be consumed by any class consuming this one
with 'PONAPI::Role::HasErrors';

has _links => (
    init_arg  => undef,
    traits    => [ 'Hash' ],
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { +{} },
    handles   => {
        has_links => 'count',
    }
);

sub add_links {
    my $self  = shift;
    my $links = shift;

    $links and ref $links eq 'HASH'
        or die "[__PACKAGE__] add_links: arg must be a hashref\n";

    my %valid_args = map { $_ => 1 } qw< about self related pagination page >;

    $valid_args{$_} or die "[__PACKAGE__] add_links: invalid key: $_\n"
        for keys %{ $links };

    my $builder = PONAPI::Links::Builder->new;
    $links->{about}      and $builder->add_about( $links->{about} );
    $links->{self}       and $builder->add_self( $links->{self} );
    $links->{related}    and $builder->add_related( $links->{related} );
    $links->{pagination} and $builder->add_pagination( $links->{pagination} );

    my $result = $builder->build;

    if ( $result->has_errors ) {
        $self->add_errors( $result->get_errors );
    } else {
        @{ $self->_links }{ keys %{ $result } } = values %{ $result };
    }

    return $self;
};

1;

__END__
