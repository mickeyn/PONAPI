# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::RetrieveAll;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsGET',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasFields',
     'PONAPI::Client::Request::Role::HasFilter',
     'PONAPI::Client::Request::Role::HasInclude',
     'PONAPI::Client::Request::Role::HasPage',
     'PONAPI::Client::Request::Role::HasSort';

sub path   {
    my $self = shift;
    return '/' . $self->type;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
