package Dancer2::Plugin::JSONAPI::Role::Error;

use Moo::Role;

sub jsonapi_error {
    my ( $dsl, $status, $error ) = @_;
    $dsl->response->status( $status || 500 );
    $dsl->response->content({
        jsonapi => { version => "1.0" },
        errors  => [ $error || "unkown" ],
    });
    $dsl->header( "Content-Type" => "application/vnd.api+json" );
    $dsl->halt;
}

no Moose::Role; 1;
