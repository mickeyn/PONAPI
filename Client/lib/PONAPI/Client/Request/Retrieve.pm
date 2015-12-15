# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::Retrieve;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsGET',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasFields',
     'PONAPI::Client::Request::Role::HasFilter',
     'PONAPI::Client::Request::Role::HasInclude',
     'PONAPI::Client::Request::Role::HasPage';

sub path   {
    my $self = shift;
    return '/' . $self->type . '/' . $self->id;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
