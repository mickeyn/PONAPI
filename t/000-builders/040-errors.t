#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Errors::Builder');
}

=pod

TODO:

=cut

subtest '... testing constructor' => sub {

    my $b = PONAPI::Errors::Builder->new;
    isa_ok($b, 'PONAPI::Errors::Builder');

    can_ok( $b, $_ ) foreach qw[
        id     has_id
        status has_status
        code   has_code
        title  has_title
        detail has_detail
        source has_source

        add_source

        build
    ];

};

subtest '... testing add and get source' => sub {
	my $builder = PONAPI::Errors::Builder->new;
    
    ok(!$builder->has_source, "error should't have source before adding it");
    
	is(
		exception { $builder->add_source( { pointer => '/data/error/el' } ) },
	    undef,
	    '... got the (lack of) error we expected'
    );
	
	ok($builder->has_source, "error should have source after adding it");    
    
    is_deeply(
	        $builder->build(),
	        {
	            source => { pointer => '/data/error/el', }
	        },
	        '... Relationship with multiple data',
	    );    
};

subtest '... testing add source with error' => sub {
	my $builder = PONAPI::Errors::Builder->new;
    
    ok(!$builder->has_source, "error should't have source before adding it");
    
	like(
		exception { $builder->add_source( '/data/error/el' ) },
	    qr/arguments list must be key\/value pairs or a hashref/,
	    '... got the (lack of) error we expected'
    );	
};

done_testing;
