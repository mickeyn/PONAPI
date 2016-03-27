# ABSTRACT: document builder - null resource
package PONAPI::Document::Builder::Resource::Null;

use Moose;

with 'PONAPI::Document::Builder';

sub build { undef }

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
