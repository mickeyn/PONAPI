# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Builder::Resource::Identifier;

use Moose;

with 'PONAPI::Builder',
     'PONAPI::Builder::Role::HasMeta';

has 'id'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'type' => ( is => 'ro', isa => 'Str', required => 1 );

sub build {
    my $self   = $_[0];
    my $result = {};

    $result->{id}   = $self->id;
    $result->{type} = $self->type;
    $result->{meta} = $self->_meta if $self->has_meta;

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
