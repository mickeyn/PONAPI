#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use PONAPI::Relationship::Builder;

BEGIN {
	use_ok('PONAPI::Document::Builder');
	use_ok('PONAPI::Relationship::Builder');
	use_ok('PONAPI::Links::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

	my $b =
	  PONAPI::Document::Builder->new( action => 'GET',
									  type   => 'articles', );
	isa_ok( $b, 'PONAPI::Document::Builder' );

	ok( !$b->has_id, '... no id specified' );
	is( $b->action, 'GET',      '... got the expected action' );
	is( $b->type,   'articles', '... got the expected type' );

	can_ok( $b, $_ ) foreach qw[
	  id
	  has_id

	  action
	  type

	  add_errors
	  has_errors

	  add_data
	  has_data

	  add_meta
	  has_meta

	  add_links
	  has_links

	  add_included
	  has_included

	  build
	];

};

subtest '... testing constructor w/id' => sub {

	my $b =
	  PONAPI::Document::Builder->new(
									  id     => '10',
									  action => 'GET',
									  type   => 'articles',
	  );
	isa_ok( $b, 'PONAPI::Document::Builder' );

	ok( $b->has_id, '... we have an id specified' );
	is( $b->id,     '10',       '... and the ID is what we expected' );
	is( $b->action, 'GET',      '... got the expected action' );
	is( $b->type,   'articles', '... got the expected type' );
};

subtest '... testing constructor errors' => sub {

	like(
		  exception { PONAPI::Document::Builder->new },
		  qr/^Attribute \(.+\) is required at /,
		  '... got the error we expected'
	);

	like(
		  exception { PONAPI::Document::Builder->new( action => 'GET' ) },
		  qr/^Attribute \(type\) is required at /,
		  '... got the error we expected'
	);

	like(
		  exception { PONAPI::Document::Builder->new( action => 'GETTAH' ) },
		  qr/^Attribute \(action\) does not pass the type constraint/,
		  '... got the error we expected'
	);

	like(
		  exception { PONAPI::Document::Builder->new( type => 'articles' ) },
		  qr/^Attribute \(action\) is required at /,
		  '... got the error we expected'
	);

};

SKIP:{
	skip "this fails on tha add_data to the Document builder because the comments relationship in the added data has itself 2 data's", 1;
	
	subtest '... building a complete document using builders' => sub {
										  
		my $author_links = PONAPI::Links::Builder->new
		  						->add_self("http://example.com/articles/1/relationships/author")
		  						->add_related("http://example.com/articles/1/author");								  
	  	my $author_relationship = PONAPI::Relationship::Builder->new
	   		->add_data({ type => "people", id => "9"})	
	  		->add_links($author_links->build());
	  		
	  	my $comments_links = PONAPI::Links::Builder->new
	  						->add_self("http://example.com/articles/1/relationships/comments")
	  						->add_related("http://example.com/articles/1/comments"); 
	  	my $comments_relationship = PONAPI::Relationship::Builder->new
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
		my $builder = PONAPI::Document::Builder->new( action => 'GET', type   => 'articles', id     => '1')
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
							PONAPI::Links::Builder->new
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
								PONAPI::Relationship::Builder->new
	  								->add_data({ "type" => "people", "id" => "2" })	
	  								->build()
						},
					    "links" => 
					    	PONAPI::Links::Builder->new
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
								PONAPI::Relationship::Builder->new
	  								->add_data({ "type" => "people", "id" => "9" })	
	  								->build()
						},
						"links" => 
							PONAPI::Links::Builder->new
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
						"data" 	 => { "type" => "people", "id" => "2" }
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

done_testing;
