package PONAPI::CLI::Command::demo;

use PONAPI::CLI -command;

use strict;
use warnings;

use File::Temp qw( tempdir );
use Path::Class;
use Plack::Runner;

use Plack::Middleware::MethodOverride;
use PONAPI::Server;

sub abstract    { "Run a DEMO PONAPI::Server" }
sub description { "This tool will run a demo server with a mock DB" }

sub opt_spec {
    return (
        [ "port=i", "specify a port for the server (default=5000)" ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

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

    my @options = ();
    $opt->{port} and push @options => ( '-port', $opt->{port} );

    my $app = Plack::Middleware::MethodOverride->wrap(
        PONAPI::Server->new(
            'repository.class' => 'Test::PONAPI::Repository::MockDB',
            'ponapi.config_dir' => $dir
        )->to_app()
    );

    my $runner = Plack::Runner->new;
    $runner->parse_options(@options);
    $runner->run($app);
}

1;
