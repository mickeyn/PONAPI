package PONAPI::Role::HasLinks;

use strict;
use warnings;

use Moose::Role;

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
        or die "[__PACKAGE__] add_links: arg must be a hashref";

    my %valid_args = map { $_ => 1 } qw< about self related pagination page >;

    $valid_args{$_} or die "[__PACKAGE__] add_links: invalid key: $_"
        for keys %{ $links };

    my $links_builder = PONAPI::Links::Builder->new;
    $links->{about}      and $links_builder->add_about( $links->{about} );
    $links->{self}       and $links_builder->add_self( $links->{self} );
    $links->{related}    and $links_builder->add_related( $links->{related} );
    $links->{pagination} and $links_builder->add_pagination( $links->{pagination} );

    my $build_result = $links_builder->build;

    @{ $self->_links }{ keys %{ $build_result } } = values %{ $build_result };

    return $self;
};

1;

__END__
