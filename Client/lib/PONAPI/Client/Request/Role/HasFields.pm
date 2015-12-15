# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::Role::HasFields;

use Moose::Role;

has fields => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_fields',
);

no Moose::Role; 1;

__END__
