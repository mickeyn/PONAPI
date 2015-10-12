package Dancer2::Plugin::JSONAPI::MediaType;

use Dancer2::Plugin;

my $jsonapi_mediatype = 'application/vnd.api+json';
my $match_jsonapi_mt  = qr/^application\/vnd\.api\+json/;

on_plugin_import {
    my $dsl = shift;

    ### add 'before' hook to check type

    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                # enforce json-api Content-Type (no extra params)
                my $ct = $dsl->request->headers->{'content-type'};
                $ct and $ct eq $jsonapi_mediatype
                    or $dsl->send_error(
                        "[JSON-API] missing Content-Type header", 415
                    );

                # if json-api is sent in Accept headers,
                # at least one instance must not contain any params

                my @accept = grep { /$match_jsonapi_mt/ }
                    split /,/ => $dsl->request->headers->{'accept'};

                if ( @accept > 0 ) {
                    grep { $_ eq $jsonapi_mediatype } @accept
                        or $dsl->send_error(
                            "[JSON-API] Accept header contains only parameterized instances of json-api", 406
                        );
                }

                # all good
                return;
            },
        )
    );


    ### add 'after' hook to force content-type

    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                $dsl->header( 'Content-Type' => $jsonapi_mediatype );
            },
        )
    );
};

register_plugin;

1;
