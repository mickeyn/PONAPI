# ABSTRACT: ponapi CLI query runner
package PONAPI::CLI::RunQuery;

use strict;
use warnings;

use JSON::XS;
use HTTP::Tiny;

sub run {
    my ( $port, $query_string ) = @_;

    my $url = $query_string || random_url( $port );

    my $res = HTTP::Tiny->new->get( $url, {
        headers => {
            'Content-Type' => 'application/vnd.api+json',
        },
    });

    die "Failed to connect to a local server (try 'ponapi demo -s' to start one)\n"
        unless $res and ref($res) eq 'HASH' and $res->{status} < 500;

    print "\nGET $url\n\n";
    print $res->{protocol} . " " . $res->{status} . " " . $res->{reason} . "\n";

    print "Content-Type: " . $res->{headers}{'content-type'} . "\n\n";

    my $json = JSON::XS->new;
    print $json->pretty(1)->encode( $json->decode($res->{content}) );
}

sub random_url {
    my $port = shift;

    my %rels = (
        articles => {
            id      => [ 1, 2, 3 ],
            include => [qw< comments authors >],
            fields  => [qw< body title created updated status >],
        },
        comments => {
            id      => [ 5, 12 ],
            include => [qw< articles >],
        },
        people   => {
            id      => [ 42, 88, 91 ],
            include => [qw< articles >],
            fields  => [qw< name age gender >],
        },
    );

    my $type = ( keys %rels )[ _rand(\%rels) ];

    my $id = _rand(2) ? '/' . $rels{$type}{id}->[ _rand( $rels{$type}{id} ) ] : "";

    my @type_inc = @{ $rels{$type}{include} };
    my @include  = _rand(2)
        ? ( scalar @type_inc > 1 ? map { _rand(2) ? $_ : () } @type_inc : @type_inc )
        : ();

    my $include = @include ? "include=" . ( join ',' => @include ) : "";

    my @fields = _rand(2) ? map { _rand(2) ? $_ : () } @{ $rels{$type}{fields} } : ();
    my $fields = @fields  ? "fields[$type]=" . ( join ',' => @fields, @include ) : "";

    my $sort = ( !$id and _rand(2) )
        ? "sort=" . ( _rand(2) ? '-' : () ) . ( 'id', @fields )[ _rand(@fields+1) ]
        : "";

    my $is_query = ( $include || $fields || $sort ? "?" : "" );

    my $url = "http://localhost:$port/$type"
        . $id . $is_query . join( '&' => grep { $_ } $include, $fields, $sort );

    return $url;
}

sub _rand {
    my $s =
        @_ > 1                ? scalar( @_ )            :
        ref($_[0]) eq 'HASH'  ? scalar( keys %{$_[0]} ) :
        ref($_[0]) eq 'ARRAY' ? scalar( @{$_[0]} )      :
        $_[0];

    return int(rand($s));
}

1;
