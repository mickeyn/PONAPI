package PONAPI::DAO::Request::ResourceCollection;

use Moose;

extends 'PONAPI::DAO::Request';

has data => (
    is        => 'ro',
    isa       => 'ArrayRef[HashRef]',
    predicate => 'has_data',
);

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::ResourceCollection -- PONAPI::DAO::Request extension for one-to-many requests

=head1 DESCRIPTION

For certain API operations, the 'data' key in the request will be an arrayref
of resources, rather than a simple resource.  In those cases -- C<create_relationships> and and C<delete_relationships> -- we use this class
instead of C<PONAPI::DAO::Request>.
