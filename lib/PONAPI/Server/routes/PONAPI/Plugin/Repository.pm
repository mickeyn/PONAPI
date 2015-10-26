package PONAPI::Plugin::Repository;

use Dancer2::Plugin;

use PONAPI::DAO;

use Module::Runtime ();

my $DAO;

on_plugin_import {
    my $dsl = shift;

    ### read ponapi configuration

    # force explicit setting of 'sort' support configuration
    my $repository_class = $dsl->config->{ponapi}{repository}{class}
        || die "[PONAPI Server] missing repository_class configuration\n";

    my @repository_args = @{ $dsl->config->{ponapi}{repository}{args} };

    my $repository = Module::Runtime::use_module($repository_class)->new( @repository_args );

    $DAO = PONAPI::DAO->new( repository => $repository );
};

register DAO => sub { $DAO };

register_plugin;

1;
