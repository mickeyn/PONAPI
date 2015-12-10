# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Builder::Resource::Null;

use Moose;

with 'PONAPI::Builder';

sub build { undef }

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
