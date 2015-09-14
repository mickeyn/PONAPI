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
	local $TODO = "Need to check what is wrong here.";

	subtest '... adding relationship to resource' => sub {
		
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
	        id => "5",
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
	    		id   => '1',
        		type => 'articles',
	    		relationships => {
	            	data =>
		            	[
			                {
			                    id => "5",
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