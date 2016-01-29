# ABSTRACT: ponapi manual
package PONAPI::CLI::Command::manual;

use PONAPI::CLI -command;

use strict;
use warnings;

use Pod::Perldoc;

sub abstract      { "Show the PONAPI server manual" }
sub description   { "This tool will run perldoc PONAPI::Manual" }
sub opt_spec      {}
sub validate_args {}

sub execute {
    local $ARGV[0] = "PONAPI::Manual";
    Pod::Perldoc->run()
}

1;
