package Dancer2::Plugin::JSONAPI::Params;

use Dancer2::Plugin;

with 'Dancer2::Plugin::JSONAPI::Role::Error';

my %sort_config = (
    enabled       => 0,
    is_restricted => 0,
    allowed_keys  => {},
);

on_plugin_import {
    my $dsl = shift;
    _read_sort_config($dsl);
};

register jsonapi_parameters => sub {
    my $dsl = shift;

    my $type = $dsl->route_parameters->get('resource_type');

    my %params = (
        type     => $type,
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
            or jsonapi_error( $dsl, 400, {
                message => "[JSON-API] Bad request (unsupported parameters)"
            });

        # 'sort' requested but not supported
        if ( $p eq 'sort' and !$sort_config{enabled} ) {
            jsonapi_error( $dsl, 400, {
                message => "[JSON-API] Server-side sorting not supported"
            });
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
        if ( $p eq 'sort' ) {
            $params{'sort'} = +[
                map { /^(\-?)(.+)$/; +[ $2, ( $1 ? 'DESC' : 'ASC' ) ] }
                @values
            ];

            # check key restriction
            if ( $sort_config{is_restricted} ) {
                for ( map { $_->[0] } @{ $params{'sort'} } ) {
                    exists $sort_config{allowed_keys}{$type}{$_}
                        or jsonapi_error( $dsl, 400, {
                            message => "[JSON-API] sorting is restricted for specific keys, "
                                . "please check specific documentation for the server",
                        });
                }
            }
        }
    }

    return \%params;
};

register_plugin;


sub _read_sort_config {
    my $dsl = shift;

    # force explicit setting of 'sort' support configuration
    my $sort_enabled = $dsl->config->{jsonapi}{sort}{enabled};
    if ( defined $sort_enabled and grep { lc($sort_enabled) eq $_ } qw< 1 true yes > ) {
        $sort_config{enabled} = 1;
    } elsif ( defined $sort_enabled and ! grep { lc($sort_enabled) eq $_ } qw< 0 false no > ) {
        die "[JSON-API] configuration missing: {jsonapi}{supports_sort}";
    }


    # read keys restriction config (if set)
    my $conf_keys = $dsl->config->{jsonapi}{sort}{allowed_keys};
    defined $conf_keys or return;

    ref $conf_keys eq 'HASH' or die "[JSON-API] bad configuration jsonapi-sort-allowed-keys";

    for my $k ( keys %{ $conf_keys } ) {
        $sort_config{allowed_keys}{$k} =
            ( ref $conf_keys->{$k} eq 'ARRAY' ) ? +{ map { $_ => 1 } @{ $conf_keys->{$k} }         } :
            ( ! ref $conf_keys->{$k} )          ? +{ map { $_ => 1 } split /,/ => $conf_keys->{$k} } :
            die "[JSON-API] bad configuration jsonapi-sort-allowed-keys";
    }

    keys %{ $sort_config{allowed_keys} } > 0 and $sort_config{is_restricted} = 1;
}

1;
