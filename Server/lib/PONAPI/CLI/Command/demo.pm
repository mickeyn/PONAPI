# ABSTRACT: ponapi demo running command line utility
package PONAPI::CLI::Command::demo;

use PONAPI::CLI -command;

use strict;
use warnings;

sub abstract    { "Run a DEMO PONAPI server" }
sub description { "This tool will run a demo server with a mock DB" }

sub opt_spec {
    return (
        [ "s|server",  "Run a local PONAPI demo server" ],
        [ "q|query:s", "Send a random/provided query to local server" ],
        [ "p|port=i",  "Specify a port for the server (default=5000)" ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("(only) one of server (-s) or query (-q [STR]) is required.\n")
        unless exists $opt->{s} xor exists $opt->{q};

    $self->{port} = $opt->{port} || $opt->{p} || 5000;

    $self->{query_string} = "";

    if ( exists $opt->{q} and $opt->{q} ) {
        $opt->{q} =~ s|^/||;
        $self->{query_string} =
            ( $opt->{q} !~ /^http/ ? 'http://localhost:' . $self->{port} . '/' : '' )
            . $opt->{q}
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    $self->run_server() if exists $opt->{s};
    $self->run_query()  if exists $opt->{q};
}

sub run_server {
    my $self = shift;

    require Plack::Runner;
    require Plack::Middleware::MethodOverride;
    require PONAPI::Server;

    require File::Temp;
    File::Temp->import('tempdir');

    require Path::Class;
    Path::Class->import('file');

    my $dir  = tempdir( CLEANUP => 1 );
    my $conf = file( $dir . '/server.yml' );
    $conf->spew(<<"DEFAULT_CONF");
server:
  spec_version: "1.0"
  sort_allowed: "false"
  send_version_header: "true"
  send_document_self_link: "true"
  links_type: "relative"
  respond_to_updates_with_200: "false"

repository:
  class:  "Test::PONAPI::Repository::MockDB"
  args:   []
DEFAULT_CONF

    my $app = Plack::Middleware::MethodOverride->wrap(
        PONAPI::Server->new(
            'repository.class' => 'Test::PONAPI::Repository::MockDB',
            'ponapi.config_dir' => $dir
        )->to_app()
    );

    my $runner = Plack::Runner->new;
    $runner->parse_options( '-port', $self->{port} );
    $runner->run($app);
}

sub run_query {
    my $self = shift;

    require JSON::XS;
    require HTTP::Tiny;

    my $url = $self->{query_string} || $self->random_url();

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
    my $self = shift;

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

    my $type = ( keys %rels )[ int(rand( scalar keys %rels )) ];

    my $id = "";
    if ( int(rand(2)) % 2 == 0 ) {
        my $_id  = $rels{$type}{id}->[ int(rand(scalar @{ $rels{$type}{id} } )) ];
        $id = "/$_id";
    }

    my $fields = "";
    if ( int(rand(2)) % 2 == 0 ) {
        my @fields  = map { int(rand(2)) % 2 ? $_ : () } @{ $rels{$type}{fields} };
        $fields = "fields[$type]=" . ( join ',' => @fields )
            if @fields;
    }

    my $include = "";
    if ( int(rand(2)) % 2 == 0 ) {
        my @_inc = @{ $rels{$type}{include} };
        my @include = scalar @_inc > 1
            ? map { int(rand(2)) % 2 ? $_ : () } @_inc
            : @_inc;

        $include = "include=" . ( join ',' => @include)
            if @include;
    }

    my $query = ( $include || $fields ? "?" : "" );
    my $sep   = ( $include && $fields ? "&" : "" );

    my $url = 'http://localhost:' . $self->{port}
            . "/$type" . $id . $query . $include . $sep . $fields;

    return $url;
}

1;
