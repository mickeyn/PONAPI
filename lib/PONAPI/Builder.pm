package PONAPI::Builder;

use strict;
use warnings;

use PONAPI::Document::Builder;

sub create {
    my ( $class, $action, $type, $args ) = @_;

    $action or die "[$class] create: missing action\n";
    $type   or die "[$class] create: missing type\n";

    !ref($action) and grep { $action eq $_ } qw< GET POST PATCH DELETE >
        or die "[$class] create: invalid action\n";

    !ref($type) and $type or die "[$class] create: invalid type\n";

    $args and ref($args) eq 'HASH' or die "[$class] create: invalid args\n";

    return PONAPI::Document::Builder->new( action => $action, type => $type, %$args );
}

1;
