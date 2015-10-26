package Dancer2::Plugin::JSONAPI::Params;

use Dancer2::Plugin;

with 'Dancer2::Plugin::JSONAPI::Role::Error';

my $supports_sort = 0;

on_plugin_import {
    my $dsl = shift;

    # force explicit setting of 'sort' support configuration
    my $config_sort = $dsl->config->{jsonapi}{supports_sort};
    if ( defined $config_sort and grep { lc($config_sort) eq $_ } qw< 1 true yes > ) {
        $supports_sort = 1;
    } elsif ( defined $config_sort and ! grep { lc($config_sort) eq $_ } qw< 0 false no > ) {
        die "[JSON-API] configuration missing: {jsonapi}{supports_sort}";
    }
};

register jsonapi_parameters => sub {
    my $dsl = shift;

    my %params = (
        type     => $dsl->route_parameters->get('resource_type'),
        id       => $dsl->route_parameters->get('resource_id'),
        rel_type => $dsl->route_parameters->get('relationship_type'),
        data     => $dsl->body_parameters->get('data'),
        fields => {}, filter => {}, page => {}, include => [], 'sort' => [],
    );

    # loop over query parameters (unique keys)
    for my $k ( keys %{ $dsl->query_parameters } ) {
        my ( $p, $f ) = $k =~ /^ (\w+?) (?:\[(\w+)\])? $/x;

        # valid parameter names
        grep { $p eq $_ } qw< fields filter page include sort >
            or jsonapi_error(
                $dsl,
                { message => "[JSON-API] Bad request (unsupported parameters)" },
                400
            );

        # 'sort' requested but not supported
        if ( $p eq 'sort' and !$supports_sort ) {
            jsonapi_error(
                $dsl,
                { message => "[JSON-API] Server-side sorting not supported" },
                400
            );
        }

        # values can be passed as CSV
        my @values = map { split /,/ } $dsl->query_parameters->get_all($k);

        # values passed on in array-ref
        grep { $p eq $_ } qw< fields filter >
            and $params{$p}{$f} = \@values;

        # page info has one value per request
        $p eq 'page' and $params{$p}{$f} = $values[0];

        # values passed on in hash-ref
        $p eq 'include' and $params{include} = \@values;

        # sort values: indicate direction
        $p eq 'sort' and $params{'sort'} = +[
            map { /^(\-?)(.+)$/; +[ $2, ( $1 ? 'DESC' : 'ASC' ) ] }
            @values
        ];
    }

    return \%params;
};

register_plugin;

1;
