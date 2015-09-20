#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Builder::Document')
}

subtest '... single document builder' => sub {
    my $root = PONAPI::Builder::Document->new;
    isa_ok($root, 'PONAPI::Builder::Document');

    ok($root->is_root, '... this is the root');

    ok(!$root->has_resource, '... we do not have a resource builder yet');

    my $resource;
    is(
        exception { 
            $resource = $root->add_resource( type => 'foo', id => 100 ) 
        },
        undef,
        '... set the resource sucessfully'
    );
    isa_ok($resource, 'PONAPI::Builder::Resource');

    my $links = $root->links_builder;
    isa_ok($links, 'PONAPI::Builder::Links');

    my $errors = $root->errors_builder;
    isa_ok($errors, 'PONAPI::Builder::Errors');

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
        isa_ok($relationship, 'PONAPI::Builder::Relationship');

        my $links = $resource->links_builder;
        isa_ok($links, 'PONAPI::Builder::Links');  

        is($relationship->parent, $resource, '... the parent of relationship is the resource builder');
        is($relationship->parent->parent, $root, '... the grand-parent of relationship is the root builder');

        is($relationship->find_root, $root, '... the grand-parent of relationship is the root builder (find_root)');

        is($links->parent, $resource, '... the parent of links is the resource builder');
        is($links->parent->parent, $root, '... the grand-parent of links is the root builder');

        is($links->find_root, $root, '... the grand-parent of links is the root builder (find_root)');

        subtest '... relationship builder' => sub {
            my $resource_id = $relationship->resource_id_builder;
            isa_ok($resource_id, 'PONAPI::Builder::Resource::ID');

            my $links = $relationship->links_builder;
            isa_ok($links, 'PONAPI::Builder::Links');        

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
        isa_ok($resource, 'PONAPI::Builder::Resource');

        is($resource->parent, $root, '... the parent of resource is the document builder');
        is($resource->find_root, $root, '... the parent of resource is the document builder (find_root)');
    };
};

done_testing;
