#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Builder::Document');
}

my $ERROR = {
    detail => "an error has occured",
    status => 555,
};

subtest '... creating a document with errors' => sub {

    my $doc = PONAPI::Builder::Document->new( version => '1.0' );
    isa_ok( $doc, 'PONAPI::Builder::Document');

    $doc->raise_error( 400, $ERROR );

    my $GOT = $doc->build->{errors}[0];

    is_deeply(
        $GOT,
        $ERROR,
        "... the document now has errors",
    );

};

done_testing;
