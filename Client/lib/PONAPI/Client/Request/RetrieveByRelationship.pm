# ABSTRACT: request - retrieve by relationship
package PONAPI::Client::Request::RetrieveByRelationship;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsGET',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasRelationshipType',
     'PONAPI::Client::Request::Role::HasFields',
     'PONAPI::Client::Request::Role::HasFilter',
     'PONAPI::Client::Request::Role::HasInclude',
     'PONAPI::Client::Request::Role::HasPage';

has uri_template => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/{type}/{id}/{rel_type}' },
);

sub path   {
    my $self = shift;
    return +{ type => $self->type, id => $self->id, rel_type => $self->rel_type };
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
