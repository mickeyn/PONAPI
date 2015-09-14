#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Links::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Links::Builder->new;
    isa_ok($b, 'PONAPI::Links::Builder');

    can_ok( $b, $_ ) foreach qw[
        add_self
        has_self

        add_related
        has_related

        add_pagination
        has_pagination

        has_page
        add_page

        build
    ];

};

subtest '... test set, get back and build self' => sub {
    my $links = PONAPI::Links::Builder->new;
    isa_ok($links, 'PONAPI::Links::Builder');

    my $x = $links->add_self('/resource/1');

    isa_ok(
        $x,
        'PONAPI::Links::Builder',
        '... our builder always returns an instance of a builder'
    );
    is($x, $links, '... and the instance is ourself');

    is($links->_self, '/resource/1', '... we are getting self URL back');

    my ($result, $error) = $links->build;

    ok((not defined $error), '... no error found');
    is_deeply(
        $result,
        { self => '/resource/1' },
        '... got the build result as expected'
    );
};

subtest '... test set, get back and build multiple fields' => sub {
    my $links = PONAPI::Links::Builder->new;
    isa_ok($links, 'PONAPI::Links::Builder');

    is(
        exception {
            $links->add_self('/resource/1')
                  ->add_related('/resource/1/related/2')
                  ->add_pagination({
                        first => '/resources/1',
                        last  => '/resources/5',
                        next  => '/resources/4',
                        prev  => '/resources/2',
                   });
        }, undef,
        '... added self, related and pagination successfully'
    );

    is($links->_self, '/resource/1', 'we are getting self back');
    is($links->_related, '/resource/1/related/2', 'we are getting related back');
    is_deeply(
        $links->_pagination,
        {
            first   => '/resources/1',
            last    => '/resources/5',
            next    => '/resources/4',
            prev    => '/resources/2',
        },
        '.... got the pagination'
    );

    my ($result, $error) = $links->build;

    ok((not defined $error), '... no error found');

    is_deeply(
        $result,
        {
            self    => '/resource/1',
            related => '/resource/1/related/2',
            first   => '/resources/1',
            last    => '/resources/5',
            next    => '/resources/4',
            prev    => '/resources/2',
        },
        '.... built the result we expected'
    );

};

subtest '... test set and get of link objects' => sub {
		my $links = PONAPI::Links::Builder->new;
	    isa_ok($links, 'PONAPI::Links::Builder');	
    
    is(
        exception {
            $links->add_self({
						href => 'resource/1',
						meta => { ext_id => 234 },
            		})
                  ->add_related({
						href => 'resource/152',
						meta => { ext_id => -123 },
            		});
        }, undef,
        '... added self and related successfully'
    );
    
    my ($result, $error) = $links->build;

    ok((not defined $error), '... no error found');
    
    is_deeply(
        $result,
        {
            self    => {
						href => 'resource/1',
						meta => { ext_id => 234 },
            		},
            related => {
						href => 'resource/152',
						meta => { ext_id => -123 },
            		},
         },
        '.... built the result we expected'
    );

};

TODO:{
	subtest '... test errors' => sub {
		local $TODO = "Need to validate input, not yet implemented";
		
		my $links = PONAPI::Links::Builder->new;
	    isa_ok($links, 'PONAPI::Links::Builder');	
	    
	    like(
	    	exception { 
	    		$links->add_self({
	        		href => 'resource/1',
	        		address => 'resource/1',
					meta => { ext_id => 234 },
	        	}
	        )},
	        qr/invalid key: address/,
	        '...address is an invalid attribute for the links object (self)'
		);	
	        
	    like(
	    	exception { 
	    		$links->add_self({
					meta => { ext_id => 234 },
	        	}
	        )},
	        qr/missing key: href/,
	        '...href is a mandatory attribute for the links object (self)'
		);
		
		like(
	    	exception { 
	    		$links->add_related({
	        		href => 'resource/1',
	        		address => 'resource/1',
					meta => { ext_id => 234 },
	        	}
	        )},
	        qr/invalid key: address/,
	        '...address is an invalid attribute for the links object (related)'
		);	
	        
	    like(
	    	exception { 
	    		$links->add_related({
					meta => { ext_id => 234 },
	        	}
	        )},
	        qr/missing key: href/,
	        '...href is a mandatory attribute for the links object (related)'
		);		
	};
}

done_testing;
