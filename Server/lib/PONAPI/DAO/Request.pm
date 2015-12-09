package PONAPI::DAO::Request;

use Moose;
use JSON::XS;

use PONAPI::Builder::Document;

has repository => (
    is       => 'ro',
    does     => 'PONAPI::DAO::Repository',
    required => 1,
);

has document => (
    is       => 'ro',
    isa      => 'PONAPI::Builder::Document',
    required => 1,
);

has req_base => (
    is       => 'ro',
    isa      => 'Str',
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

has json => (
    is      => 'ro',
    isa     => 'JSON::XS',
    default => sub { JSON::XS->new->allow_nonref->utf8->canonical },
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    my $version = delete $args{version}
        || die "[__PACKAGE__] missing arg `version`";

    $args{document} = PONAPI::Builder::Document->new( version => $version );

    return \%args;
}

sub BUILD {
    my ( $self, $args ) = @_;
    my $type = $self->type;

    # `type` exists
    return $self->_bad_request( "Type `$type` doesn't exist.", 404 )
        unless $self->repository->has_type( $type );

    # validate `id` parameter
    if ( $self->does('PONAPI::DAO::Request::Role::HasID') ) {
        $self->_bad_request( "`id` is missing for this request" )
            unless $self->has_id;
    }
    elsif ( defined $args->{id} ) {
        $self->_bad_request( "`id` is not allowed for this request" );
    }

    # validate `rel_type` parameter
    if ( $self->does('PONAPI::DAO::Request::Role::HasRelationshipType') ) {
        defined $args->{rel_type}
            ? $self->_validate_rel_type
            : $self->_bad_request( "`relationship type` is missing for this request" );
    }
    elsif ( defined $args->{rel_type} ) {
        $self->_bad_request( "`relationship type` is not allowed for this request" );
    }

    # validate `include` parameter
    if ( defined $args->{include} ) {
        $self->does('PONAPI::DAO::Request::Role::HasInclude')
            ? $self->_validate_include
            : $self->_bad_request( "`include` is not allowed for this request" );
    }

    # validate `fields` parameter
    if ( defined $args->{fields} ) {
        $self->does('PONAPI::DAO::Request::Role::HasFields')
            ? $self->_validate_fields
            : $self->_bad_request( "`fields` is not allowed for this request" );
    }

    # validate `filter` parameter
    if ( defined $args->{filter} ) {
        $self->does('PONAPI::DAO::Request::Role::HasFilter')
            ? $self->_validate_filter
            : $self->_bad_request( "`filter` is not allowed for this request" );
    }

    # validate `sort` parameter
    if ( defined $args->{sort} ) {
        $self->does('PONAPI::DAO::Request::Role::HasSort')
            ? $self->_validate_sort
            : $self->_bad_request( "`sort` is not allowed for this request" );
    }

    # validate `page` parameter
    if ( defined $args->{page} ) {
        $self->does('PONAPI::DAO::Request::Role::HasPage')
            ? $self->_validate_page
            : $self->_bad_request( "`page` is not allowed for this request" );
    }

    # validate `data`
    if ( exists $args->{data} ) {
        if ( $self->can('data') ) {
            $self->_validate_data;
        }
        else {
            $self->_bad_request( "request body is not allowed" );
        }
    }
    elsif ( $self->can('has_data') ) {
        $self->_bad_request( "request body is missing `data`" );
    }
}

sub response {
    my ( $self, @headers ) = @_;
    my $doc = $self->document;

    $doc->add_self_link( $self->req_base )
        if $self->send_doc_self_link;

    return ( $doc->status, \@headers, $doc->build );
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

sub _get_resource_for_meta {
    my $self = shift;

    my $self_link = $self->document->get_self_link
        // ( join "/" => grep defined, '', @{$self}{qw/type id rel_type/} );

    my $resource = $self_link
                 . " => "
                 . $self->json->encode( $self->data );

    return $resource;
}

sub _handle_error {
    my ($self, $e) = @_;
    {
        local $@;
        if ( !eval { $e->isa('PONAPI::DAO::Exception'); } ) {
            warn "$e";
            return $self->_server_failure;
        }
    }

    my $status = $e->status;
    if ( $e->sql_error ) {
        my $msg = $e->message;
        $self->_bad_request( "SQL error: $msg", $status );
    }
    elsif ( $e->bad_request_data ) {
        my $msg = $e->message;
        $self->_bad_request( "Bad request data: $msg", $status );
    }
    else {
        # Unknown error..?
        warn $e->as_string;
        $self->_server_failure;
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
