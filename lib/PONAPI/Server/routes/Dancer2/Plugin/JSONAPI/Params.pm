package Dancer2::Plugin::JSONAPI::Params;

use Dancer2::Plugin;

on_plugin_import {
    my $dsl = shift;
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                # read fields[], filter[] and page[] paramerts
                for my $k ( qw< fields filter page > ) {
                    my %params;

                    for ( $dsl->query_parameters->keys ) {
                        /^$k\[(.+)\]$/ or next;
                        $params{$1} = +[
                            split /,/ => $dsl->query_parameters->get($_)
                        ];
                        $dsl->query_parameters->remove($_);
                    }

                    $dsl->query_parameters->add( $k => \%params );
                }

                # include paramerts
                my %include = map { $_ => 1 }
                    map { split /,/ } $dsl->query_parameters->get_all('include');

                $dsl->query_parameters->remove('include')
                    and $dsl->query_parameters->add( 'include', \%include );
            },
        )
    );
};

register_plugin;

1;
