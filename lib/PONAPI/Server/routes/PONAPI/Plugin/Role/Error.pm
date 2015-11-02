package PONAPI::Plugin::Role::Error;

use Moo::Role;

sub ponapi_error {
    my ( $dsl, $error, $status ) = @_;
    $dsl->response->status( $status || 500 );
    $dsl->response->content({
        jsonapi => { version => "1.0" },
        errors  => [ $error || "unkown" ],
    });
    $dsl->header( "Content-Type" => "application/vnd.api+json" );
    $dsl->halt;
}

no Moo::Role; 1;
__END__
