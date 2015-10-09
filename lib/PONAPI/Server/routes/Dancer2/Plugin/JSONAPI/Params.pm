package Dancer2::Plugin::JSONAPI::Params;

use Dancer2::Plugin;

on_plugin_import {
    my $dsl = shift;

    # force required jsonapi configuration
    my $supports_sort = config->{jsonapi}{supports_sort};
    defined $supports_sort and ( $supports_sort == 0 or $supports_sort == 1 )
        or die "[JSONAPI] configuration missing: {jsonapi}{supports_sort}";

    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                my %params = ( fields => {}, filter => {}, page => {}, include => {} );

                for my $k ( keys %{ $dsl->query_parameters } ) { # unique keys
                    my ( $p, $f ) = $k =~ /^ (\w+?) (?:\[(\w+)\])? $/x;
                    grep { $p eq $_ } qw< fields filter page include sort >
                        or $dsl->send_error(
                            "[JSON-API] Bad request (unsupported parameters)", 400
                        );

                    # sort support is set in config->{jsonapi}{supports_sort}
                    if ( $p eq 'sort' and !$supports_sort ) {
                        $dsl->send_error(
                            "[JSON-API] Server-side sorting not supported", 400
                        );
                    }

                    my @values = map { split /,/ } $dsl->query_parameters->get_all($k);
                    $dsl->query_parameters->remove($k);

                    grep { $p eq $_ } qw< fields filter page >
                        and $params{$p}{$f} = \@values;

                    $p eq 'include'
                        and $params{include}{$_} = 1 for @values;
                }

                $dsl->query_parameters->add( $_, $params{$_} ) for keys %params;
            },
        )
    );
};

register_plugin;

1;
