package PONAPI::Role::HasLinks;

use strict;
use warnings;

use Moose::Role;

has _links => (
    init_arg  => undef,
    is        => 'ro',
    predicate => 'has_links',
    writer    => '_set_links',
);

sub add_links {
    my $self  = shift;
    my $links = shift;

    $links and ref $links eq 'HASH'
        or die "[__PACKAGE__] add_links: arg must be a hashref";

    my %valid_args = map { $_ => 1 } qw< about self related pagination page >;

    for ( keys %{ $links } ) {
        exists $valid_args{$_}
            or die "[__PACKAGE__] add_links: invalid key: $_";
    }

    my $links_builder = $self->_links // PONAPI::Links::Builder->new;
    $links->{about}      and $links_builder->add_about( $links->{about} );
    $links->{self}       and $links_builder->add_self( $links->{self} );
    $links->{related}    and $links_builder->add_related( $links->{related} );
    $links->{pagination} and $links_builder->add_pagination( $links->{pagination} );

    $self->_set_links( $links_builder );

    return $self;
};

1;

__END__
