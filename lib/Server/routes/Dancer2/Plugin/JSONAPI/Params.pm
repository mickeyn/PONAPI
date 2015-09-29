package Dancer2::Plugin::JSONAPI::Params;

use Dancer2::Plugin;

on_plugin_import {
    my $dsl = shift;
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                # break fields[] & page[] paramerts
                for my $k ( qw< fields page > ) {
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

                # sort flags
                my @sort =
                    map { /^(\-)?(.+)$/; +[ $2, ( $1 ? 'DESC' : 'ASC' ) ] }
                    split ',' => $dsl->query_parameters->get('sort');

                $dsl->query_parameters->remove('sort')
                    and $dsl->query_parameters->add( 'sort', \@sort );

                # default undef so we don't have to check it in all handlers
                $dsl->query_parameters->get('include')
                    or $dsl->query_parameters->add( 'include', undef );
            },
        )
    );
};

register_plugin;

1;
