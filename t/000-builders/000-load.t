#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

## ----------------------------------------------------------------------------

package PONAPI::Builder {
    use Moose::Role;

    requires 'build';

    has 'parent' => (
        is        => 'rw',
        does      => 'PONAPI::Builder',
        predicate => 'has_parent',
        weak_ref  => 1,
    );

    sub is_root { ! $_[0]->has_parent }

    sub find_root {
        my $current = $_[0];
        $current = $current->parent until $current->is_root;
        return $current;
    }

    sub raise_error {
        my $self = shift;

        # XXX:
        # we could check the args here and look for
        # a `level` key which would tell us if we
        # should throw an exception (immediate, fatal error)
        # or we should just stash the error and continue.
        # It might get funky, but it would be nice to
        # unify some error handling, maybe, perhaps
        # I am not sure.
        # - SL

        $self->find_root->errors_builder->add_error( @_ );

        # What should this return?
        return;
    }
}

package PONAPI::Role::HasLinksBuilder {
    use Moose::Role;

    has 'links_builder' => (
        is        => 'ro',
        isa       => 'PONAPI::Links::Builder',
        lazy      => 1,
        predicate => 'has_links_builder',
        builder   => '_build_links_builder',
    );

    sub _build_links_builder { PONAPI::Links::Builder->new( parent => $_[0] ) }

    sub add_link {
        my ($self, @args) = @_;
        $self->links_builder->add_link( @args );
        return $self;
    }

    sub add_links {
        my ($self, @args) = @_;
        $self->links_builder->add_links( @args );
        return $self;
    }
}

package PONAPI::Role::HasMeta {
    use Moose::Role;

    has _meta => (
        init_arg => undef,
        traits   => [ 'Hash' ],
        is       => 'ro',
        isa      => 'HashRef',
        default  => sub { +{} },
        handles  => {
            has_meta  => 'count',
        }
    );

    sub add_meta {
        my ($self, %args) = shift;
        @{ $self->_meta }{ keys %args } = values %args;
        return $self;
    }
}

## ----------------------------------------------------------------------------

package PONAPI::Document::Builder {
    use Moose;

    with 'PONAPI::Builder',
         'PONAPI::Role::HasLinksBuilder',
         'PONAPI::Role::HasMeta';

    has '_included' => (
        traits  => [ 'Array' ],
        is      => 'ro',
        isa     => 'ArrayRef[ PONAPI::Resource::Builder ]',
        lazy    => 1,
        default => sub { +[] },
        handles => {
            'has_included'  => 'count',
            # private ...
            '_add_included' => 'push',
        }
    );

    sub add_included {
        my ($self, %args) = @_;
        my $builder = PONAPI::Resource::Builder->new( parent => $self, %args );
        $self->_add_included( $builder );
        return $builder;
    }

    has 'resource_builder' => (
        is        => 'ro',
        isa       => 'PONAPI::Resource::Builder',
        predicate => 'has_resource_builder',
        writer    => '_set_resource_builder',
    );

    sub set_resource {
        my ($self, %args) = @_;
        my $builder = PONAPI::Resource::Builder->new( %args, parent => $_[0] );
        $self->_set_resource_builder( $builder );
        return $builder;
    }

    has 'errors_builder' => (
        is        => 'ro',
        isa       => 'PONAPI::Errors::Builder',
        lazy      => 1,
        predicate => 'has_errors_builder',
        builder   => '_build_errors_builder',
    );

    sub _build_errors_builder { PONAPI::Errors::Builder->new( parent => $_[0] ) }

    sub build {
        my $self   = $_[0];
        my $result = +{ jsonapi => { version => "1.0" } };

        if ( $self->has_errors_builder ) {
            $result->{errors} = $self->errors_builder->build;
        }
        else {
            $result->{meta}   = $self->_meta                if $self->has_meta;
            $result->{links}  = $self->links_builder->build if $self->has_links_builder;

            if ( $self->has_resource_builder ) {
                $result->{data}     = $self->resource_builder->build;
                $result->{included} = +[ map { $_->build } @{ $self->_included } ]
                    if $self->has_included;
            }
        }

        return $result;
    }
}

package PONAPI::Resource::Builder {
    use Moose;

    with 'PONAPI::Builder',
         'PONAPI::Role::HasLinksBuilder',
         'PONAPI::Role::HasMeta';

    has 'id'   => ( is => 'ro', isa => 'Str', required => 1 );
    has 'type' => ( is => 'ro', isa => 'Str', required => 1 );

    has '_attributes' => (
        traits  => [ 'Hash' ],
        is      => 'ro',
        isa     => 'HashRef',
        lazy    => 1,
        default => sub { +{} },
        handles => {
            'has_attributes'    => 'count',
            'has_attribute_for' => 'exists',
            # private ...
            '_add_attribute' => 'set',
            '_get_attribute' => 'get',
        }
    );

    sub add_attribute {
        my $self  = $_[0];
        my $key   = $_[1];
        my $value = $_[2];

        $self->raise_error(
            title => 'Attribute key conflict, a relation already exists for key: ' . $key
        ) if $self->has_relationship_for( $key );

        $self->_add_attribute( $key, $value );

        return $self;
    }

    sub add_attributes {
        my ($self, %args) = @_;
        $self->add_attribute( $_, $args{ $_ } ) foreach keys %args;
        return $self;
    }

    has '_relationships' => (
        traits  => [ 'Hash' ],
        is      => 'ro',
        isa     => 'HashRef[ PONAPI::Relationship::Builder ]',
        lazy    => 1,
        default => sub { +{} },
        handles => {
            'has_relationships'    => 'count',
            'has_relationship_for' => 'exists',
            # private ...
            '_add_relationship' => 'set',
            '_get_relationship' => 'get',
        }
    );

    sub add_relationship {
        my ($self, $key, %args) = @_;

        $self->raise_error(
            title => 'Relationship key conflict, an attribute already exists for key: ' . $key
        ) if $self->has_attribute_for( $key );

        my $builder = PONAPI::Relationship::Builder->new( parent => $self, %args );
        $self->_add_relationship( $key => $builder );
        return $builder
    }

    sub build {
        my $self   = $_[0];
        my $result = {};

        $result->{id}            = $self->id;
        $result->{type}          = $self->type;
        $result->{attributes}    = $self->_attributes          if $self->has_attributes;
        $result->{links}         = $self->links_builder->build if $self->has_links_builder;
        $result->{meta}          = $self->_meta                if $self->has_meta;
        $result->{relationships} = {
            map {
                $_ => $self->_get_relationship( $_ )->build
            } keys %{ $self->_relationships }
        } if $self->has_relationships;

        return $result;
    }
}

package PONAPI::ResourceID::Builder {
    use Moose;

    with 'PONAPI::Builder',
         'PONAPI::Role::HasMeta';

    has 'id'   => ( is => 'ro', isa => 'Str', required => 1 );
    has 'type' => ( is => 'ro', isa => 'Str', required => 1 );

    sub build {
        my $self   = $_[0];
        my $result = {};

        $result->{id}   = $self->id;
        $result->{type} = $self->type;
        $result->{meta} = $self->_meta if $self->has_meta;

        return $result;
    }
}

package PONAPI::Links::Builder {
    use Moose;

    with 'PONAPI::Builder',
         'PONAPI::Role::HasMeta';

    has '_links' => (
        traits  => [ 'Hash' ],
        is      => 'ro',
        isa     => 'HashRef',
        lazy    => 1,
        default => sub { +{} },
        handles => {
            'has_link' => 'exists',
            'get_link' => 'get',
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

        $result->{meta} = $self->_meta if $self->has_meta;

        return $result;
    }
}

package PONAPI::Errors::Builder {
    use Moose;

    with 'PONAPI::Builder';

    has '_errors' => (
        traits  => [ 'Array' ],
        is      => 'ro',
        isa     => 'ArrayRef[ HashRef ]',
        lazy    => 1,
        default => sub { +[] },
        handles => {
            'has_errors' => 'count',
            # private ...
            '_add_error' => 'push',
        }
    );

    sub add_error {
        my $self  = $_[0];
        my $error = $_[1];

# TODO: verify error structure

        $self->_add_error( $error );
    }

    sub build {
        my $self   = $_[0];
        my $result = +[ @{ $self->_errors } ];
        return $result;
    }
}

package PONAPI::Relationship::Builder {
    use Moose;

    with 'PONAPI::Builder',
         'PONAPI::Role::HasLinksBuilder',
         'PONAPI::Role::HasMeta';

    has 'resource_id_builder' => (
        is        => 'ro',
        isa       => 'PONAPI::ResourceID::Builder',
        predicate => 'has_resource_id_builder',
        writer    => '_set_resource_id_builder',
    );

    sub BUILD {
        my ($self, $param) = @_;

        $self->_set_resource_id_builder(
            PONAPI::ResourceID::Builder->new(
                parent => $self,
                id     => $param->{id},
                type   => $param->{type}
            )
        );

        $self->resource_id_builder->add_meta( %{ $param->{meta} } )
            if $param->{meta};
    }

    sub build {
        my $self   = $_[0];
        my $result = {};

        $self->raise_error(
            title => 'You must specify a resource identifier to relate with'
        ) unless $self->has_resource_id_builder;

        $result->{data}  = $self->resource_id_builder->build;
        $result->{links} = $self->links_builder->build if $self->has_links_builder;
        $result->{meta}  = $self->_meta                if $self->has_meta;

        return $result;
    }
}

## ----------------------------------------------------------------------------

subtest '... single document builder' => sub {
    my $root = PONAPI::Document::Builder->new;
    isa_ok($root, 'PONAPI::Document::Builder');

    ok($root->is_root, '... this is the root');

    ok(!$root->has_resource_builder, '... we do not have a resource builder yet');

    is(
        exception { $root->set_resource( type => 'foo', id => 100 ) },
        undef,
        '... set the resource sucessfully'
    );

    my $resource = $root->resource_builder;
    isa_ok($resource, 'PONAPI::Resource::Builder');

    my $links = $root->links_builder;
    isa_ok($links, 'PONAPI::Links::Builder');

    my $errors = $root->errors_builder;
    isa_ok($errors, 'PONAPI::Errors::Builder');

    ok(!$resource->is_root, '... this is not the root');
    ok(!$links->is_root, '... this is not the root');
    ok(!$errors->is_root, '... this is not the root');

    is($resource->parent, $root, '... the parent of resource is our root builder');
    is($links->parent, $root, '... the parent of links is our root builder');
    is($errors->parent, $root, '... the parent of errors is our root builder');

    is($resource->find_root, $root, '... the parent of resource is our root builder (find_root)');
    is($links->find_root, $root, '... the parent of links is our root builder (find_root)');
    is($errors->find_root, $root, '... the parent of errors is our root builder (find_root)');

    subtest '... resource builder' => sub {

        my $relationship = $resource->add_relationship('foo' => ( type => 'foo', id => 200 ));
        isa_ok($relationship, 'PONAPI::Relationship::Builder');

        my $links = $resource->links_builder;
        isa_ok($links, 'PONAPI::Links::Builder');

        is($relationship->parent, $resource, '... the parent of relationship is the resource builder');
        is($relationship->parent->parent, $root, '... the grand-parent of relationship is the root builder');

        is($relationship->find_root, $root, '... the grand-parent of relationship is the root builder (find_root)');

        is($links->parent, $resource, '... the parent of links is the resource builder');
        is($links->parent->parent, $root, '... the grand-parent of links is the root builder');

        is($links->find_root, $root, '... the grand-parent of links is the root builder (find_root)');

        subtest '... relationship builder' => sub {
            my $resource_id = $relationship->resource_id_builder;
            isa_ok($resource_id, 'PONAPI::ResourceID::Builder');

            my $links = $relationship->links_builder;
            isa_ok($links, 'PONAPI::Links::Builder');

            is($resource_id->parent, $relationship, '... the parent of resource_id is the relationship builder');
            is($resource_id->parent->parent, $resource, '... the grand-parent of resource_id is the resource builder');
            is($resource_id->parent->parent->parent, $root, '... the great-grand-parent of resource_id is the root builder');

            is($resource_id->find_root, $root, '... the great-grand-parent of resource_id is the root builder (find_root)');

            is($links->parent, $relationship, '... the parent of links is the relationship builder');
            is($links->parent->parent, $resource, '... the grand-parent of links is the resource builder');
            is($links->parent->parent->parent, $root, '... the great-grand-parent of links is the root builder');

            is($links->find_root, $root, '... the great-grand-parent of links is the root builder (find_root)');
        };
    };

    subtest '... included' => sub {
        my $resource = $root->add_included( type => 'foo', id => 200 );
        isa_ok($resource, 'PONAPI::Resource::Builder');

        is($resource->parent, $root, '... the parent of resource is the document builder');
        is($resource->find_root, $root, '... the parent of resource is the document builder (find_root)');
    };
};

## ----------------------------------------------------------------------------

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;

my $EXPECTED = $JSON->decode(q[
{
    "data":{
        "type":"articles",
        "id":"1",
        "attributes":{
            "title":"Rails is Omakase",
            "body":"WHAT?!?!?!"
        },
        "relationships":{
            "author":{
                "links":{
                    "self":"/articles/1/relationships/author",
                    "related":"/articles/1/author"
                },
                "data":{
                    "type":"people",
                    "id":"9"
                }
            }
        }
    },
    "included":[
        {
            "type":"people",
            "id":"9",
            "attributes":{
                "name":"DHH"
            },
            "links":{
                "self":"/people/9"
            }
        }
    ]
}
]);

my $GOT = PONAPI::Document::Builder
    ->new
        ->set_resource( id => 1, type => 'articles' )
            ->add_attributes(
                title => 'Rails is Omakase',
                body  => 'WHAT?!?!?!'
            )
            ->add_relationship( 'author' => ( id => 9, type => 'people' ) )
                ->add_links(
                    self    => '/articles/1/relationships/author',
                    related => '/articles/1/author'
                )
            ->parent
        ->parent
        ->add_included( id => 9, type => 'people' )
            ->add_attributes( name => 'DHH' )
            ->add_link( self => '/people/9' )
        ->parent
    ->build
;

warn Dumper $GOT;
is_deeply( $GOT, $EXPECTED, '... got the expected result' );

## ----------------------------------------------------------------------------

done_testing;
