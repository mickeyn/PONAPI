package PONAPI::Links::Builder;
use Moose;

with 'PONAPI::Builder';

has '_links' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
    handles => {
        'has_links' => 'count',
        'has_link'  => 'exists',
        'get_link'  => 'get',
        # private ...
        '_add_link' => 'set',
    }
);

sub add_link {
    my $self = $_[0];
    my $rel  = $_[1];
    my $url  = $_[2];
    $self->_add_link( $rel => $url );
    return $self;
}

sub add_links {
    my ($self, %links) = @_;
    $self->add_link( $_, $links{ $_ } ) foreach keys %links;
    return $self;
}

sub build {
    my $self   = $_[0];
    my $result = {};

    foreach my $key ( keys %{ $self->_links } ) {
        $result->{ $key } = $self->get_link( $key );
    }

    return $result;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;