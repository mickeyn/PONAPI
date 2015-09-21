#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Resource');
}

subtest '... adding attributes to resource' => sub {

	my $builder = PONAPI::Builder::Resource->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($builder, 'PONAPI::Builder::Resource');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');

    is(
	    exception {
	    	$builder->add_attributes(
		    	this 		=> "should",
		    	be			=> "an",
		    	attribute	=> "object",
		    )
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

subtest '... adding complex attributes to resource' => sub {
	my $builder = PONAPI::Builder::Resource->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($builder, 'PONAPI::Builder::Resource');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');

    is(
	    exception {
	    	$builder->add_attributes(
		    	an_attribute 	=> {
		    		this 		=> "should",
		    		be			=> "a",
		    		complex		=> "json",
		    	}
	    	)
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
