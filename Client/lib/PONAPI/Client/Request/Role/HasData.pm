# ABSTRACT: request - role - has data
package PONAPI::Client::Request::Role::HasData;

use Moose::Role;

has _data => (
    init_arg  => 'data',
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
);

has data => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_data',
);

sub _build_data {
    my $self = shift;
    my $data = $self->_data;

    $data->{type} = $self->type if !defined $data->{type};
    $data->{id}   = $self->id   if !defined $data->{id}
                        && $self->does('PONAPI::Client::Request::Role::HasId');

    return $data;
}

no Moose::Role; 1;

__END__
