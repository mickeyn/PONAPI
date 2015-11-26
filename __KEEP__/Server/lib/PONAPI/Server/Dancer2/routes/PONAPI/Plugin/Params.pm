package PONAPI::Plugin::Params;

use Dancer2::Plugin;

with 'PONAPI::Plugin::Role::Error';
with 'PONAPI::Plugin::Role::Config';

my $sort_allowed = 0;

on_plugin_import {
    my $dsl = shift;
    $sort_allowed = ponapi_config_get_server_sort($dsl);
};

register ponapi_parameters => sub {
    my $dsl = shift;

    my %params = (
        req_base => "".$dsl->request->base,
        type     => $dsl->route_parameters->get('resource_type'),
        id       => $dsl->route_parameters->get('resource_id')       || '',
        rel_type => $dsl->route_parameters->get('relationship_type') || '',
        data     => ( $dsl->request->method eq 'GET' ? undef : $dsl->body_parameters->get('data') || {} ),
        fields => {}, filter => {}, page => {}, include => [], 'sort' => [],
    );

    # loop over query parameters (unique keys)
    for my $k ( keys %{ $dsl->query_parameters } ) {
        my ( $p, $f ) = $k =~ /^ (\w+?) (?:\[(\w+)\])? $/x;

        # valid parameter names
        grep { $p eq $_ } qw< fields filter page include sort >
            or ponapi_error(
                $dsl,
                { message => "{JSON:API} Bad request (unsupported parameters)" },
                400
            );

        # 'sort' requested but not supported
        if ( $p eq 'sort' and !$sort_allowed ) {
            ponapi_error(
                $dsl,
                { message => "{JSON:API} Server-side sorting not supported" },
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
