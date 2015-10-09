package Dancer2::Plugin::JSONAPI::MediaType;

use Dancer2::Plugin;

my $jsonapi_mediatype = 'application/vnd.api+json';

on_plugin_import {
    my $dsl = shift;

    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                # Content-Type is $jsonapi_mediatype
                my $ct = $dsl->request->headers->{'content-type'}
                    || $dsl->send_error("[JSON-API] missing Content-Type header", 415);
                $ct eq $jsonapi_mediatype and return;

                # if it contains params --> error 415
                substr( $ct, 0, length($jsonapi_mediatype) ) eq $jsonapi_mediatype
                    and $dsl->send_error("[JSON-API] Content-Type is not $jsonapi_mediatype", 415);

                # alternatively, we have it in Accept (at least once clean with no parameters)
                my @accept = split /,/ => $dsl->request->headers->{'accept'};
                grep { $_ eq $jsonapi_mediatype } @accept
                    or $dsl->send_error("[JSON-API] Accept doesn't contain $jsonapi_mediatype entry", 406);

                # all good
                return;
            },
        )
    );

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
