package PONAPI::Builder::Resource::ID;
use Moose;

with 'PONAPI::Builder';

has 'id'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'type' => ( is => 'ro', isa => 'Str', required => 1 );

sub build {
    my $self   = $_[0];
    my $result = {};

    $result->{id}   = $self->id;
    $result->{type} = $self->type;

    return $result;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;
