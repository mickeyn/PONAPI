package PONAPI::CLI::RunServer;

use strict;
use warnings;

use Plack::Runner;
use Plack::Middleware::MethodOverride;
use PONAPI::Server;

use File::Temp  qw( tempdir );
use Path::Class qw( file );

sub run {
    my $port = shift;

    my $dir = _create_dir();

    my $app = Plack::Middleware::MethodOverride->wrap(
        PONAPI::Server->new(
            'repository.class' => 'Test::PONAPI::Repository::MockDB',
            'ponapi.config_dir' => $dir
        )->to_app()
    );

    my $runner = Plack::Runner->new;
    $runner->parse_options( '-port', $port || 5000 );
    $runner->run($app);
}

sub _create_dir {
    my $dir  = tempdir( CLEANUP => 1 );

    my $conf = file( $dir . '/server.yml' );
    $conf->spew(<<"DEFAULT_CONF");
server:
  spec_version: "1.0"
  sort_allowed: "true"
  send_version_header: "true"
  send_document_self_link: "true"
  links_type: "relative"
  respond_to_updates_with_200: "false"

repository:
  class:  "Test::PONAPI::Repository::MockDB"
  args:   []
DEFAULT_CONF

    return $dir;
}

1;
