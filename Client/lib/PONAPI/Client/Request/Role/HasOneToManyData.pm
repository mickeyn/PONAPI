package PONAPI::Client::Request::Role::HasOneToManyData;

use Moose::Role;

with 'PONAPI::Client::Request::Role::HasData';

has data => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    required => 1,
);

no Moose::Role; 1;
__END__
