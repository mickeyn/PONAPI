package PONAPI::DAO::Request;

use Moose;

has document => (
    is       => 'ro',
    isa      => 'PONAPI::Builder::Document',
    default  => sub { PONAPI::Builder::Document->new() }
);

has req_base => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has send_doc_self_link => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has id => (
    is  => 'ro',
    isa => 'Str',
);

has rel_type => (
    is  => 'ro',
    isa => 'Str',
);

has data => (
    is        => 'ro',
);

for ( qw< fields filter page > ) {
    has $_ => (
        traits   => [ 'Hash' ],
        is       => 'ro',
        isa      => 'HashRef',
        default  => sub { +{} },
        handles  => {
            "has_$_" => 'count',
        },
    );
}

for ( qw< include sort > ) {
    has $_ => (
        traits   => [ 'Array' ],
        is       => 'ro',
        isa      => 'ArrayRef',
        default  => sub { +[] },
        handles  => {
            "has_$_" => 'count',
        },
    );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
