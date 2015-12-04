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

has json => (
    is      => 'ro',
    isa     => 'JSON::XS',
    default => sub { JSON::XS->new->allow_nonref->utf8->canonical },
);

sub check_has_id       { $_[0]->has_id       or  return $_[0]->_bad_request( "`id` is missing"                 ); 1; }
sub check_has_rel_type { $_[0]->has_rel_type or  return $_[0]->_bad_request( "`relationship type` is missing"  ); 1; }

my %role_to_param = (
    HasID          => 'id',
    HasRelationshipType => 'rel_type',
    HasFields      => 'fields',
    HasFilter      => 'filter',
    HasInclude     => 'include',
    HasPage        => 'page',
    HasSort        => 'sort',
    
);
sub BUILD {
    my ($self, $args) = @_;

    my $repo = $self->repository;
    my $type = $self->type;

    # `type` exists
    $repo->has_type( $type )
        or $self->_bad_request( "Type `$type` doesn't exist.", 404 );

    if ( $self->does('PONAPI::DAO::Request::Role::HasDataMethods') ) {
        $self->has_data && $self->_validate_data;
    }
    else {
        $self->_bad_request("Parameter `data` is not allowed for this request")
            if exists $args->{data} && $self->has_body;
    } 

    foreach my $role ( keys %role_to_param ) {
        my $param = $role_to_param{$role};
        if ( $self->does("PONAPI::DAO::Request::Role::$role") ) {
            my $has_method = "has_${param}";
            if ( $self->$has_method ) {
                my $validate   = "_validate_${param}";
                $self->$validate() if $self->can($validate)
            }
        }
        else {
            my $status = $param eq 'rel_type' ? 404 : 400;
            $self->_bad_request("Parameter `$param` is not allowed for this request", $status)
                if exists $args->{$param};
        }
    }

    return $self
}

sub response {
    my ( $self, @headers ) = @_;
    my $doc = $self->document;

    $doc->add_self_link( $self->req_base )
        if $self->send_doc_self_link;

    return ( $doc->status, \@headers, $doc->build );
}

sub _validate_rel_type {
    my $self = shift;

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
