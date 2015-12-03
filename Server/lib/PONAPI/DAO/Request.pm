package PONAPI::DAO::Request;

use Moose;
use JSON::XS;

use PONAPI::Builder::Document;
use PONAPI::DAO::Constants;

has 'repository' => (
    is       => 'ro',
    does     => 'PONAPI::DAO::Repository',
    required => 1,
);

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

sub validate {
    my $self = shift;
    my $repo = $self->repository;
    my $type = $self->type;

    # `type` exists
    $repo->has_type( $type )
        or $self->_bad_request( "Type `$type` doesn't exist.", 404 );

    # `include` types & relationships
    $self->does('PONAPI::DAO::Request::Role::HasInclude')
        and $self->_validate_included();

    # `fields` types & relationships
    $self->does('PONAPI::DAO::Request::Role::HasFields')
        and $self->_validate_fields();

    # `rel_type` relationship exists
    $self->_validate_rel_type();

    # check `data`
    $self->does('PONAPI::DAO::Request::Role::HasDataAttribute')
        and $self->_validate_data();

    return $self;
}

sub _validate_rel_type {
    my $self = shift;
    return unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 )
        unless $self->repository->has_relationship( $type, $rel_type );
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
