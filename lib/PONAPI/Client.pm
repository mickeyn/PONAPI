package PONAPI::Client;

use Moose;

use Hijk;
use JSON::XS qw( decode_json );

use PONAPI::Client::Request::Create;
use PONAPI::Client::Request::CreateRelationships;
use PONAPI::Client::Request::Retrieve;
use PONAPI::Client::Request::RetrieveAll;
use PONAPI::Client::Request::RetrieveRelationships;
use PONAPI::Client::Request::RetrieveByRelationship;
use PONAPI::Client::Request::Update;
use PONAPI::Client::Request::Delete;
use PONAPI::Client::Request::DeleteRelationships;

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'localhost' },
);

has port => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { 5000 },
);


### public methods

sub create {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::Create->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub create_relationships {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::CreateRelationships->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve_all {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::RetrieveAll->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::Retrieve->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve_relationships {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::RetrieveRelationships->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve_by_relationship {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::RetrieveByRelationship->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub update {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::Update->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub delete : method {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::Delete->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}

sub delete_relationships {
    my ( $self, %args ) = @_;
    my $request = PONAPI::Client::Request::DeleteRelationships->new( %args );
    return $self->_send_ponapi_request( $request->request_params );
}


### private methods

sub _send_ponapi_request {
    my $self = shift;
    my %args = @_;

    my $res = Hijk::request({
        %args,
        host => $self->host,
        port => $self->port,
        head => [ 'Content-Type' => 'application/vnd.api+json' ],
    });

    return decode_json( $res->{body} );
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
