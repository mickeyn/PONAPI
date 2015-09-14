#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Resource::Builder');
}

TODO: {
	local $TODO = "add_attributes expect a hashref where any valid json should be expected";

	subtest '... adding attributes to resource' => sub {
		
		my $builder = PONAPI::Resource::Builder->new(
	        id   => '1',
	        type => 'articles',
	    );
	    
	    is(
		    exception { 
		    	$builder->add_attributes({
			    	this 		=> "should",
			    	be			=> "an",
			    	attribute	=> "object",
			    })
		    },
		    undef,
		    '... got the (lack of) error we expected'
	    );
	    
	    is_deeply(
	    	$builder->build,
	    	{
	    		id   => '1',
	        	type => 'articles',
	    		attributes => {
	    			this 		=> "should",
			    	be			=> "an",
			    	attribute	=> "object",	
	    		}
	    	},
	    	'... built as expected'
	    )
	};
}

subtest '... adding complex attributes to resource' => sub {
	my $builder = PONAPI::Resource::Builder->new(
        id   => '1',
        type => 'articles',
    );
    
    is(
	    exception { 
	    	$builder->add_attributes({
		    	an_attribute 	=> {
		    		this 		=> "should",
		    		be			=> "a",
		    		complex		=> "json",
		    	}
	    	})
	    },
	    undef,
	    '... got the (lack of) error we expected'
    );
    
    is_deeply(
    	$builder->build,
    	{
    		id   => '1',
        	type => 'articles',
    		attributes => {
		    	an_attribute 	=> {
		    		this 		=> "should",
		    		be			=> "a",
		    		complex		=> "json",
		    	}
    		}
    	},
    	'... built as expected'
    );
};

done_testing;