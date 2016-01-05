# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Builder::Resource;

use Moose;

use PONAPI::Builder::Relationship;

with 'PONAPI::Builder',
     'PONAPI::Builder::Role::HasLinksBuilder',
     'PONAPI::Builder::Role::HasMeta';

has id   => ( is => 'ro', isa => 'Str', required => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );

has _attributes => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        'has_attributes'    => 'count',
        'has_attribute_for' => 'exists',
        # private ...
        '_add_attribute'   => 'set',
        '_get_attribute'   => 'get',
        '_keys_attributes' => 'keys',
    }
);

has _relationships => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[ PONAPI::Builder::Relationship ]',
    lazy     => 1,
    default  => sub { +{} },
    handles  => {
        'has_relationships'    => 'count',
        'has_relationship_for' => 'exists',
        # private ...
        '_add_relationship'   => 'set',
        '_get_relationship'   => 'get',
        '_keys_relationships' => 'keys',
    }
);

sub add_attribute {
    my ( $self, $key, $value ) = @_;

    $self->raise_error( 400,
        title => 'Attribute key conflict, a relation already exists for key: ' . $key
    ) if $self->has_relationship_for( $key );

    $self->_add_attribute( $key, $value );

    return $self;
}

sub add_attributes {
    my ( $self, %args ) = @_;
    $self->add_attribute( $_, $args{ $_ } ) foreach keys %args;
    return $self;
}

sub add_relationship {
    my ( $self, $key, $resource, $collection ) = @_;

    $self->raise_error( 400,
        title => 'Relationship key conflict, an attribute already exists for key: ' . $key
    ) if $self->has_attribute_for( $key );

    my @resources =
        ( ref $resource eq 'ARRAY' ) ? @$resource :
        ( ref $resource eq 'HASH'  ) ? $resource  :
        die 'Relationship resource information must be a reference (HASH or ARRAY)';

    my $builder = $self->has_relationship_for($key)
        ? $self->_get_relationship($key)
        : PONAPI::Builder::Relationship->new(
            parent     => $self,
            name       => $key,
            collection => $collection,
          );

    $builder->add_resource( $_ ) foreach @resources;

    $self->_add_relationship( $key => $builder );
}

sub add_self_link {
    my $self = shift;
    my $base = $self->find_root->req_base;
    $self->links_builder->add_link( self => $base . $self->{type} . '/' . $self->{id} );
    return $self;
}

sub build {
    my $self   = shift;
    my %args   = @_;
    my $result = {};

    $result->{id}    = $self->id;
    $result->{type}  = $self->type;
    $result->{links} = $self->links_builder->build if $self->has_links_builder;
    $result->{meta}  = $self->_meta                if $self->has_meta;

    # support filtered output for attributes/relationships through args
    my @field_filters;
    @field_filters = @{ $args{fields}{ $self->type } }
        if exists $args{fields} and exists $args{fields}{ $self->type };

    $result->{attributes} = +{
        map { my $v = $self->_get_attribute($_); $v ? ( $_ => $v ) : () }
        ( @field_filters ? @field_filters : $self->_keys_attributes )
    } if $self->has_attributes;

    $result->{relationships} = +{
        map { my $v = $self->_get_relationship($_); $v ? ( $_ => $v->build ) : () }
        ( @field_filters ? @field_filters : $self->_keys_relationships )
    } if $self->has_relationships;

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
