# ABSTRACT: document builder - null resource
package PONAPI::Builder::Resource::Null;

use Moose;

with 'PONAPI::Builder';

sub build { undef }

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
