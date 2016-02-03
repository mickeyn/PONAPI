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
    require PONAPI::CLI::RunServer;
    PONAPI::CLI::RunServer::run( $self->{port} );
}

sub run_query {
    my $self = shift;
    require PONAPI::CLI::RunQuery;
    PONAPI::CLI::RunQuery::run( $self->{port}, $self->{query_string} );
}

1;
