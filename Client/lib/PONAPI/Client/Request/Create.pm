# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Client::Request::Create;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsPOST',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasData';

sub path   {
    my $self = shift;
    return '/' . $self->type;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
