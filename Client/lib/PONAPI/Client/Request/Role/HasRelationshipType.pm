# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::Role::HasRelationshipType;

use Moose::Role;

has rel_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Moose::Role; 1;

__END__
