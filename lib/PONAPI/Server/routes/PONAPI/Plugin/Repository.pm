package PONAPI::Plugin::Repository;

use Dancer2::Plugin;

use PONAPI::DAO;

use Module::Runtime ();

my $DAO;

on_plugin_import {
    my $dsl = shift;

    ### read ponapi configuration

    my $repository_config = $dsl->config->{ponapi}{repository};

    my $repository_class = $repository_config->{class}
        || die "[PONAPI Server] missing repository class configuration\n";

    my @repository_args = $repository_config->{args} ? @{ $repository_config->{args} } : ();

    my $repository = Module::Runtime::use_module($repository_class)->new( @repository_args )
        || die "[PONAPI Server] failed to create a repository object\n";

    $DAO = PONAPI::DAO->new( repository => $repository );
};

register DAO => sub { $DAO };

register_plugin;

1;
