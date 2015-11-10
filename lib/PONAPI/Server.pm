package PONAPI::Server;

use strict;
use warnings;
use File::Spec;
my $routes;
BEGIN {
    my $ponapi_server = (caller(0))[1];
    my ($vol, $dir, $file) = File::Spec->splitpath($ponapi_server);
    my $server_dir = File::Spec->catpath($vol, $dir);

    $routes = File::Spec->catdir($server_dir, 'Server', 'routes');
}

use if $routes, lib => $routes;

use PONAPI;

BEGIN {
    *PONAPI::Server:: = \*PONAPI::;
}

1;

