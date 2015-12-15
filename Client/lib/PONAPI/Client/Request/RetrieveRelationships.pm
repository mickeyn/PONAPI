# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::RetrieveRelationships;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsGET',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasRelationshipType',
     'PONAPI::Client::Request::Role::HasFilter',
     'PONAPI::Client::Request::Role::HasPage';

sub path   {
    my $self = shift;
    return '/' . $self->type . '/' . $self->id .'/relationships/' . $self->rel_type;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
