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
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
);

has rel_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_rel_type',
);

for ( qw< data fields filter page > ) {
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

sub check_no_id        { $_[0]->has_id       and $_[0]->_bad_request( "`id` not allowed"                ) }
sub check_has_id       { $_[0]->has_id       or  $_[0]->_bad_request( "`id` is missing"                 ) }
sub check_has_rel_type { $_[0]->has_rel_type or  $_[0]->_bad_request( "`relationship type` is missing"  ) }
sub check_no_rel_type  { $_[0]->has_rel_type and $_[0]->_bad_request( "`relationship type` not allowed" ) }
sub check_has_data     { $_[0]->has_data     or  $_[0]->_bad_request( "request body is missing"         ) }
sub check_no_data      { $_[0]->has_data     and $_[0]->_bad_request( "request body is not allowed"     ) }

sub check_data_has_type {
    my $self = shift;

    $self->data and exists $self->data->{'type'}
        or return $self->_bad_request( "request body: `data` key is missing" );

    return 1;
}

sub _check_data_type_match {
    my $self = shift;

    $self->data and exists $self->data->{'type'} and $self->data->{'type'} eq $self->type
        or return $self->document->raise_error( 409, {
            message => "conflict between the request type and the data type"
        });

    return 1;
}

sub _bad_request {
    $_[0]->document->raise_error( 400, { message => $_[1] } );
    return;
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
