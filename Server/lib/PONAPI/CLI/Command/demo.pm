# ABSTRACT: ponapi demo running command line utility
package PONAPI::CLI::Command::demo;

use PONAPI::CLI -command;

use strict;
use warnings;

sub abstract    { "Run a DEMO PONAPI server" }
sub description { "This tool will run a demo server with a mock DB" }

sub opt_spec {
    return (
        [ "s|server", "Run a PONAPI demo server" ],
        [ "q|query",  "Execute a query from the demo server" ],
        [ "p|port=i",   "Specify a port for the server (default=5000)" ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("(only) one of server (-s) or query (-q) is required.\n")
        unless $opt->{s} xor $opt->{q};

    $self->{port} = $opt->{port} || $opt->{p} || 5000;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    $self->run_server() if $opt->{s};
    $self->run_query()  if $opt->{q};
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

    my $url = 'http://localhost:' . $self->{port} . '/articles/2?include=comments,authors';

    my $res = HTTP::Tiny->new->get( $url, {
        headers => {
            'Content-Type' => 'application/vnd.api+json',
        },
    });

    print "\nGET $url\n\n";
    print $res->{protocol} . " " . $res->{status} . " " . $res->{reason} . "\n";

    print "Content-Type: " . $res->{headers}{'content-type'} . "\n\n";

    my $json = JSON::XS->new;
    print $json->pretty(1)->encode( $json->decode($res->{content}) );
}

1;
