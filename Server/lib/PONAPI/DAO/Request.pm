package PONAPI::DAO::Request;

use Moose;
use JSON::XS;

use PONAPI::Builder::Document;

has req_base => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has has_body => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has send_doc_self_link => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

has is_valid => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 1 },
    writer  => 'set_is_valid',
);

has document => (
    is       => 'ro',
    isa      => 'PONAPI::Builder::Document',
    default  => sub { PONAPI::Builder::Document->new() }
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

has json => (
    is      => 'ro',
    isa     => 'JSON::XS',
    default => sub { JSON::XS->new->allow_nonref->utf8->canonical },
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

sub response {
    my ( $self, @headers ) = @_;
    my $doc = $self->document;

    $doc->add_self_link( $self->req_base )
        if $self->send_doc_self_link;

    return ( $doc->status, \@headers, $doc->build );
}

sub check_no_id        { $_[0]->has_id       and return $_[0]->_bad_request( "`id` not allowed"                ); 1; }
sub check_has_id       { $_[0]->has_id       or  return $_[0]->_bad_request( "`id` is missing"                 ); 1; }
sub check_has_rel_type { $_[0]->has_rel_type or  return $_[0]->_bad_request( "`relationship type` is missing"  ); 1; }
sub check_no_rel_type  { $_[0]->has_rel_type and return $_[0]->_bad_request( "`relationship type` not allowed" ); 1; }
sub check_no_body      { $_[0]->has_body     and return $_[0]->_bad_request( "request body is not allowed"     ); 1; }
sub check_has_data     { $_[0]->has_data     or  return $_[0]->_bad_request( "request body is missing `data`"  ); 1; }

sub check_data_has_type {
    my $self = shift;

    $self->data and exists $self->data->{'type'}
        or return $self->_bad_request( "data: `type` key is missing" );

    return 1;
}

sub check_data_type_match {
    my $self = shift;

    $self->data and exists $self->data->{'type'} and $self->data->{'type'} eq $self->type
        or return $self->_bad_request( "conflict between the request type and the data type", 409 );

    return 1;
}

sub validate {
    my ( $self, $repo ) = @_;
    my $type = $self->type;

    # `type` exists in repo
    $repo->has_type( $type )
        or $self->_bad_request( "Type `$type` doesn't exist.", 404 );

    # `include` relationships exist
    for ( @{ $self->include } ) {
        $repo->has_relationship( $type, $_ )
            or $self->_bad_request( "Types `$type` and `$_` are not related", 404 );
    }

    # `rel_type` relationship exists
    $self->_validate_rel_type( $repo );

    return $self;
}

sub _validate_rel_type {
    my ( $self, $repo ) = @_;
    return unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 )
        unless $repo->has_relationship( $type, $rel_type );
}

# in delete_relationships, create_relationships :
    # elsif ( $only_one_to_many{$request_type} and !$repo->has_one_to_many_relationship($type, $rel_type) ) {
    #     $doc->raise_error(400, {
    #         message => "Types `$type` and `$rel_type` are one-to-one, invalid $request_type"
    #     });
    # }

sub _bad_request {
    $_[0]->document->raise_error( $_[2]||400, { message => $_[1] } );
    $_[0]->set_is_valid(0);
    return;
}

sub _server_failure {
    $_[0]->document->raise_error( 500, {
        message => 'A fatal error has occured, please check server logs'
    });
    return;
}

use PONAPI::DAO::Constants;
use Carp 'croak';
sub verify_repository_response {
    my ($self, $response, $extra) = @_;
    
    if ( !exists $PONAPI_RETURN{$response} ) {
        croak "operation returned an unexpected value $response";
    }

    if ( $PONAPI_ERROR_RETURN{$response} ) {
        my $document = $self->document;
        if ( $response == PONAPI_CONFLICT_ERROR ) {
            my $msg = $extra->{message} || 'Conflict error in the data';
            $document->raise_error( 409, { message => $msg } );
        }
        elsif ( $response == PONAPI_UNKNOWN_RELATIONSHIP ) {
            my $msg = $extra->{message};
            if ( !$msg ) {
                my @extra_info = @{$extra}{qw/type rel_type/};
                $msg  = 'Unknown relationship';
                $msg .= sprintf(" between types %s and %s", @extra_info)
                            if @extra_info;
            }
            $document->raise_error( 404, { message => $msg } );
        }
        else {
            $document->raise_error( 400, { message => 'Unknown error' } );
        }
        return;
    }
    
    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
