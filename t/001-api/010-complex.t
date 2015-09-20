#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Document');
}

=pod

TODO:{
    local $TODO = "... update to the new API";
    
    subtest '... building a complete document using builders' => sub {
                                          
        my $author_links = PONAPI::Builder::Links->new
                                ->add_self("http://example.com/articles/1/relationships/author")
                                ->add_related("http://example.com/articles/1/author");                                
        my $author_relationship = PONAPI::Builder::Relationship->new
            ->add_data({ type => "people", id => "9"})  
            ->add_links($author_links->build());
            
        my $comments_links = PONAPI::Builder::Links->new
                            ->add_self("http://example.com/articles/1/relationships/comments")
                            ->add_related("http://example.com/articles/1/comments"); 
        my $comments_relationship = PONAPI::Builder::Relationship->new
                ->add_data({ type => "comments", id => "5" })       
                ->add_data({ type => "comments", id => "12" })
                ->add_links($comments_links->build());
            
        # a data builder could be useful here       
        my $data = 
                {
                   "type"          => "articles",
                   "id"            => "1",
                   "attributes"    => { "title" => "JSON API paints my bikeshed!" },
                   "links"         => { "self" => "http://example.com/articles/1" },
                   "relationships" => {
                       "author" => $author_relationship->build(),
                       "comments" => $comments_relationship->build(),
                   }
                }
            ;
        
        #data_builder could be used also for included resources
        my $builder = PONAPI::Builder::Document->new( action => 'GET', type   => 'articles', id     => '1')
                ->add_data($data)
                ->add_included(
                    {
                        "type"       => "people",
                        "id"         => "9",
                        "attributes" => {
                            "first-name" => "Dan",
                            "last-name"  => "Gebhardt",
                            "twitter"    => "dgeb"
                        },
                        "links" =>
                            PONAPI::Builder::Links->new
                                ->add_self("http://example.com/people/9")
                                ->build()                   
                    },
                )
                ->add_included(
                    {
                        "type"          => "comments",
                        "id"            => "5",
                        "attributes"    => { "body" => "First!" },
                        "relationships" => {
                            "author" => 
                                PONAPI::Builder::Relationship->new
                                    ->add_data({ "type" => "people", "id" => "2" }) 
                                    ->build()
                        },
                        "links" => 
                            PONAPI::Builder::Links->new
                                ->add_self("http://example.com/comments/5")
                                ->build(),
                        
                    }
                ) 
                ->add_included(
                    {
                        "type"          => "comments",
                        "id"            => "12",
                        "attributes"    => { "body" => "I like XML better" },
                        "relationships" => {
                            "author" => 
                                PONAPI::Builder::Relationship->new
                                    ->add_data({ "type" => "people", "id" => "9" }) 
                                    ->build()
                        },
                        "links" => 
                            PONAPI::Builder::Links->new
                                ->add_self("http://example.com/comments/12")
                                ->build()
                    }
                );
        
        is_deeply($builder->build(), complete_document_representation(), ".... should build it correctly")  
    };  
};

sub complete_document_representation {
    return {
        "data" => [
            {
               "type"          => "articles",
               "id"            => "1",
               "attributes"    => { "title" => "JSON API paints my bikeshed!" },
               "links"         => { "self" => "http://example.com/articles/1" },
               "relationships" => {
                   "author" => {
                       "links" => {
                           "self" => "http://example.com/articles/1/relationships/author",
                           "related" => "http://example.com/articles/1/author"
                       },
                       "data" => { "type" => "people", "id" => "9" }
                   },
                   "comments" => {
                       "links" => {
                           "self" => "http://example.com/articles/1/relationships/comments",
                           "related" => "http://example.com/articles/1/comments"
                       },
                       "data" => [
                           { "type" => "comments", "id" => "5" },
                           { "type" => "comments", "id" => "12" }
                       ]
                   }
               }
            }
        ],
        "included" => [
            {
                "type"       => "people",
                "id"         => "9",
                "attributes" => {
                    "first-name" => "Dan",
                    "last-name"  => "Gebhardt",
                    "twitter"    => "dgeb"
                },
                "links" =>
                    { "self" => "http://example.com/people/9" }
                },
            {
                "type"          => "comments",
                "id"            => "5",
                "attributes"    => { "body" => "First!" },
                "relationships" => {
                    "author" => {
                        "data"   => { "type" => "people", "id" => "2" }
                    }
                },
                "links" =>
                    { "self" => "http://example.com/comments/5" }
            },
            {
                "type"          => "comments",
                "id"            => "12",
                "attributes"    => { "body" => "I like XML better" },
                "relationships" => {
                    "author" => {
                        "data" => { "type" => "people", "id" => "9" }
                    }
                },
                "links" =>
                    { "self" => "http://example.com/comments/12" }
            }
        ]
    };
}

=cut

done_testing;
