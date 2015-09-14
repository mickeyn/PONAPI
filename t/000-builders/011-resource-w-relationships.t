#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Resource::Builder');
    use_ok('PONAPI::Relationship::Builder');
}

TODO:{
	subtest '... adding relationship to resource' => sub {
		local $TODO = "Need to check what is wrong here.";
		
		my $builder = PONAPI::Resource::Builder->new(
	        id   => '1',
	        type => 'articles',
	    );
	    
	    my $relationship_builder = PONAPI::Relationship::Builder->new;
	    
	    $relationship_builder->add_links({
	        related => "/related/2",
	        self    => "/self/1",
	    });
	    
	    $relationship_builder->add_data({
	        id => "1",
	        type => "articles",
	    });
	    
	    $relationship_builder->add_data({
	        id => "1",
	        type => "nouns"
	    });
	    
	    
	    is(
	    	exception { $builder->add_relationships($relationship_builder->build) },
	        undef,
	        '... got the (lack of) error we expected'
	    );
	    
	    is_deeply(
	    	$builder->build(),
	    	{
	    		relationships => {
	            	data =>
		            	[
			                {
			                    id => "1",
			                    type => "articles",
			                },
			                {
			                    id => "1",
			                    type => "nouns"
			                }
		            	],
		        	links => {
		                self    => "/self/1",
		                related => "/related/2",
		            }
	            }
	    	},
	    	'... built as expected' 
		);
	};
}

done_testing;