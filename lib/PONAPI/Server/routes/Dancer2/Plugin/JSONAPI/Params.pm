package Dancer2::Plugin::JSONAPI::Params;

use Dancer2::Plugin;

on_plugin_import {
    my $dsl = shift;
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                my %params = ( fields => {}, filter => {}, page => {}, include => {} );

                for my $p ( keys %{ $dsl->query_parameters } ) { # unique keys
                    my @values = map { split /,/ } $dsl->query_parameters->get_all($p);
                    $dsl->query_parameters->remove($p);

                    for my $k ( qw< fields filter page > ) {
                        $p =~ /^$k\[(.+)\]$/ or next;
                        $params{$k}{$1} = \@values;
                    }

                    $p eq 'include' and $params{include}{$_} = 1 for @values;
                }

                $dsl->query_parameters->add( $_, $params{$_} ) for keys %params;
            },
        )
    );
};

register_plugin;

1;
