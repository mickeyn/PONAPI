# ABSTRACT: request - role - has relationship-update-data
package PONAPI::Client::Request::Role::HasRelationshipUpdateData;

use Moose::Role;

with 'PONAPI::Client::Request::Role::HasData';
has data => (
    is       => 'ro',
    isa      => 'Maybe[HashRef|ArrayRef]',
    required => 1,
);

no Moose::Role; 1;

__END__
=encoding UTF-8

=head1 DESCRIPTION

Similar to L<PONAPI::Client::Request::Role::HasData>, but for relationship updates.
Unlike the rest of the spec, relationship updates can take not just a hashref of data,
but also undef, or an arrayref.

    # Replaces the specified relationship(s) with a one-to-one relationship to foo.
    $client->update_relationships( ..., data => { type => "foo", id => 4 } );

    # Replaces the
    $client->update_relationships( ..., data => [ { type => "foo", id => 4 }, { ... } ] );

    # Clears the relationship
    $client->update_relationships( ..., data => undef );
    $client->update_relationships( ..., data => [] );

The underlaying repository decides whether the one-to-one or one-to-many difference is
significant.
