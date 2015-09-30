# ABSTRACT: PONAPI - Perl JSON-API implementation (http://jsonapi.org/) v1.0
package PONAPI::Builder::Resource::Null;
use Moose;

with 'PONAPI::Builder';

sub build {
    return undef;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;
