
use Test::More;

BEGIN {
	use_ok('PONAPI::Links::Builder');
};


subtest '... test basic Links::Builder object construction' => sub {
	my $links = PONAPI::Links::Builder->new();
	isa_ok($links, 'PONAPI::Links::Builder');
};

subtest '... test set, get back and build self' => sub {
	my $links = PONAPI::Links::Builder->new();

	$links->add_self('/resource/1');

	is($links->self, '/resource/1', 'we are getting self back');

	is_deeply($links->build, {
		self => '/resource/1',
	});
};

subtest '... test set, get back and build multiple fields' => sub {
	my $links = PONAPI::Links::Builder->new();

	$links->add_self('/resource/1')
		  ->add_related('/resource/1/related/2')
		  ->add_pagination({
				first => '/resources/1',
				last  => '/resources/5',
				next  => '/resources/4',
				prev  => '/resources/2',
		   });

	is($links->self, '/resource/1', 'we are getting self back');
	is_deeply($links->build, {
		self    => '/resource/1',
		related => '/resource/1/related/2',
		first   => '/resources/1',
		last    => '/resources/5',
		next    => '/resources/4',
		prev    => '/resources/2',
	});

};

done_testing;
