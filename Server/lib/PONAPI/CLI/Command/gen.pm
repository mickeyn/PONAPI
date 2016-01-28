package PONAPI::CLI::Command::gen;

use PONAPI::CLI -command;

use strict;
use warnings;

use Path::Class;
use Module::Runtime ();

sub abstract    { "PONAPI::Server CLI tool" }
sub description { "This tool will assist you in setting up a PONAPI server" }

sub opt_spec {
    return (
        [ "dir=s",      "Server directory to be created" ],
        [ "repo=s",     "EXSISTING repository module to POINT to" ],
        [ "new_repo=s", "NEW repository module NAME to CREATE" ],
        [ "conf=s",     "copy server config file", { default => "" } ],
        [ "psgi=s",     "copy server startup script", { default => "" } ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my ( $dir, $repo, $new_repo, $conf, $psgi ) = @{$opt}{qw< dir repo new_repo conf psgi >};

    $self->usage_error("'directory name' is required.\n")
        unless $dir;

    $self->usage_error("one of new (-r) or existing (-R) 'repository' name is required.\n")
        unless $repo xor $new_repo;

    $self->usage_error("$repo is an invalid module name\n")
        if $repo and ! Module::Runtime::use_module($repo);

    $self->{_conf_content} = file($conf)->slurp()
        if $conf;

    $self->{_startup_content} = file($psgi)->slurp()
        if $psgi;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my ( $dir, $repo, $new_repo ) = @{$opt}{qw< dir repo new_repo >};

    $self->{_dir}       = $dir;
    $self->{_new_repo}  = $new_repo;
    $self->{_conf_repo} = $repo || $new_repo;

    $self->create_dir($dir);
    $self->create_repo_module();
    $self->create_conf_file();
    $self->create_psgi_file();
}

sub create_dir {
    my ( $self, $name ) = @_;
    return unless $name;

    my $dir = dir( split '/' => $name );
    unless ( -d $name or $name eq '.' or $name eq '..' ) {
        $dir->mkpath() or $self->usage_error("Failed to create directory $name\n");
    }

    return $dir;
}

sub create_repo_module {
    my $self = shift;

    my $name = $self->{_new_repo};
    return unless $name;

    $name =~ s/\.pm$//;
    $name =~ s|::|/|g;
    $name =~ s|^(.*)/||;

    my $repo_dir_name = ( $1 ? '/' . $1 : '' );

    my $repo_dir  = $self->create_dir( $self->{_dir} . '/lib' . $repo_dir_name );
    my $repo_file = $repo_dir->file( $name . '.pm' );

    $self->usage_error("Failed to create new module file\n")
        unless $repo_file->openw();

    $repo_file->spew(<<"MODULE");
package @{[ $self->{_new_repo} ]};

use Moose;

with 'PONAPI::Repository';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
MODULE
}

sub create_conf_file {
    my $self = shift;
    my $dir  = $self->{_dir};

    my $conf_dir = $self->create_dir( $dir . '/conf' );

    my $file = file( $dir . '/conf/server.yml' );

    $file->spew( $self->{_conf_content} || <<"DEFAULT_CONF" );
# PONAPI server & repository configuration file

# switch options take the positive values: "yes", 1 & "true"
#                     and negative values: "no", 0 & "false"

server:
  spec_version:            "1.0"        # {json:api} version
  sort_allowed:            "false"      # server-side sorting support
  send_version_header:     "true"       # server will send 'X-PONAPI-Server-Version' header responses
  send_document_self_link: "true"       # server will add a 'self' link to documents without errors
  links_type:              "relative"   # all links are either "relative" or "full" (inc. request base)
  respond_to_updates_with_200: "false"  # successful updates will return 200's instead of 202's

repository:
  class:  "@{[ $self->{_conf_repo} ]}"
  args:   []
DEFAULT_CONF
}

sub create_psgi_file {
    my $self = shift;
    my $dir  = $self->{_dir};

    my $psgi_dir = $self->create_dir( $dir . '/psgi' );

    my $file = file( $dir . '/psgi/ponapi.psgi' );

    $file->spew( $self->{_startup_content} || <<"DEFAULT_PSGI" );
use strict;
use warnings;
use Plack::Middleware::MethodOverride;
use PONAPI::Server;

Plack::Middleware::MethodOverride->wrap(
    PONAPI::Server->new()->to_app()
);
DEFAULT_PSGI
}

1;
