# ABSTRACT: document builder - links
package PONAPI::Document::Builder::Links;

use Moose;

with 'PONAPI::Document::Builder',
     'PONAPI::Document::Builder::Role::HasMeta';

has _links => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        'has_links' => 'count',
        'has_link'  => 'exists',
        'get_link'  => 'get',
        # private ...
        '_add_link'   => 'set',
        '_keys_links' => 'keys',
    }
);

sub add_link {
    my ( $self, $rel, $url ) = @_;
    $self->_add_link( $rel => $url );
    return $self;
}

sub add_links {
    my ( $self, %links ) = @_;
    $self->add_link( $_, $links{ $_ } ) foreach keys %links;
    return $self;
}

sub build {
    my $self   = $_[0];
    my $result = {};

    foreach my $key ( $self->_keys_links ) {
        $result->{ $key } = $self->get_link( $key );
    }

    $result->{meta} = $self->_meta if $self->has_meta;

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
