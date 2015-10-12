package PONAPI::Client::Request::Role::HasType;

use Moose::Role;

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Moose::Role; 1;
__END__
