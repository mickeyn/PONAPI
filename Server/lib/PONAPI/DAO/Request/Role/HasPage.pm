package PONAPI::DAO::Request::Role::HasPage;

use Moose::Role;

has page => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        "has_page" => 'count',
    },
);


no Moose::Role; 1;
__END__
