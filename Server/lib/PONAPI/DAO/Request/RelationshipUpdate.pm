package PONAPI::DAO::Request::RelationshipUpdate;

use Moose;

extends 'PONAPI::DAO::Request';

has data => (
    is => 'ro',
    isa => 'Maybe[HashRef|ArrayRef]',
    predicate => 'has_data',
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;
__END__
=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::RelationshipUpdate -- PONAPI::DAO::Request extension for update_relationship requests

=head1 DESCRIPTION

In C<update_relationships> operations, C<data> may be an arrayref, either empty or with resources, a single resource hashref, or even just undef.
Since that is all special behavior just for one method, C<update_relationships>
uses this sublcass of PONAPI::DAO::Request to validate that C<data> is sane.
