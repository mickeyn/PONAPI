package PONAPI::Client::Request::Role::HasData;

use Moose::Role;

has data => (
    is       => 'ro',
    isa      => 'HashRef ',
    required => 1,
);

no Moose::Role; 1;
__END__
