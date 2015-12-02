package PONAPI::DAO::Request;

use Moose;
use JSON::XS;

use PONAPI::Builder::Document;
use PONAPI::DAO::Constants;

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

    for ( $self->_get_data_elements ) {
        return $self->_bad_request( "conflict between the request type and the data type" )
            unless exists $_->{'type'};
    }

    return 1;
}

sub check_data_type_match {
    my $self = shift;

    for ( $self->_get_data_elements ) {
        return $self->_bad_request( "conflict between the request type and the data type", 409 )
            unless $_->{'type'} eq $self->type;
    }

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

    if ( $self->has_fields ) {
        my $fields = $self->fields || {};
        foreach my $fields_type ( keys %$fields ) {
            if (! $repo->has_type( $fields_type ) ) {
                $self->_bad_request( "Type `$fields_type` doesn't exist.", 404 );
            }
            else {
                $repo->type_has_fields($fields_type, $fields->{$fields_type})
                    or $self->_bad_request(
                        "Type `$fields_type` does not have at least one of the requested fields"
                    );
            }
        }
    }

    # `rel_type` relationship exists
    $self->_validate_rel_type( $repo );

    # check `data`
    if ( $self->has_data ) {
        $self->_validate_data_attributes( $repo );
        $self->_validate_data_relationships( $repo );
    }

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

sub _validate_data_attributes {
    my ( $self, $repo ) = @_;
    my $type = $self->type;

    for my $e ( $self->_get_data_elements ) {
        next unless exists $e->{attributes};
        $repo->type_has_fields( $type, [ keys %{ $e->{'attributes'} } ] )
            or $self->_bad_request(
                "Type `$type` does not have at least one of the attributes in data"
            );
    }
}

sub _validate_data_relationships {
    my ( $self, $repo ) = @_;
    my $type = $self->type;

    for my $e ( $self->_get_data_elements ) {
        my $relationships = $e->{'relationships'};
        next unless $e->{'relationships'};

        if ( %$relationships ) {
            for my $rel_type ( keys %$relationships ) {
                if ( !$repo->has_relationship( $type, $rel_type ) ) {
                    $self->_bad_request(
                        "Types `$type` and `$rel_type` are not related",
                        404
                    );
                }
                elsif ( !$repo->has_one_to_many_relationship( $type, $rel_type )
                        and ref $relationships->{$rel_type} eq 'ARRAY'
                        and @{ $relationships->{$rel_type} } > 1
                ) {
                    $self->_bad_request(
                        "Types `$type` and `$rel_type` are one-to-one, but got multiple values"
                    );
                }
            }
        }
    }
}

sub _get_data_elements {
    my $self = shift;
    return ( ref $self->data eq 'ARRAY' ? @{ $self->data } : $self->data );
}

sub _bad_request {
    my ( $self, $detail, $status ) = @_;
    $self->document->raise_error( $status||400, { detail => $detail } );
    $self->set_is_valid(0);
    return;
}

sub _server_failure {
    my $self = shift;
    $self->document->raise_error( 500, {
        detail => 'A fatal error has occured, please check server logs'
    });
    return;
}

sub _verify_repository_response {
    my ( $self, $ret, $extra ) = @_;

    die "operation returned an unexpected value"
        unless exists $PONAPI_RETURN{$ret};

    if ( $PONAPI_ERROR_RETURN{$ret} ) {
        my $doc = $self->document;
        if ( $ret == PONAPI_CONFLICT_ERROR ) {
            my $msg = $extra->{detail} || 'Conflict error in the data';
            $doc->raise_error( 409, { detail => $msg } );
        }
        elsif ( $ret == PONAPI_BAD_DATA ) {
            my $msg = $extra->{detail} || 'Bad data in request';
            $doc->raise_error( 400, { detail => $msg } );
        }
        # TODO other error codes!
        else {
            $doc->raise_error( 400, { detail => 'Unknown error' } );
        }
        return;
    }

    return 1;
}

sub _get_resource_for_meta {
    my $self = shift;

    my $self_link = $self->document->get_self_link
        // ( join "/" => grep defined, '', @{$self}{qw/type id rel_type/} );

    my $resource = $self_link
                 . " => "
                 . $self->json->encode( $self->data );

    return $resource;
}

sub _add_success_meta {
    my $self = shift;

    $self->document->add_meta(
        detail => 'successful operation on ' . $self->_get_resource_for_meta,
    );
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
