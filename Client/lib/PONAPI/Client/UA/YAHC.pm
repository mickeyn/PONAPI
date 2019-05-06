package PONAPI::Client::UA::YAHC;
# ABSTRACT: A wrapper for a YAHC UA

################################################################################
################################################################################

use strict;
use warnings;

use Moose;
use YAHC;

with 'PONAPI::Client::Role::UA';

################################################################################
################################################################################

has yahc => (
    is      => 'ro',
    isa     => 'YAHC',
    lazy    => 1,
    builder => '_build_yahc',
);

has yahc_storage => (
    is      => 'ro',
    isa     => 'Ref',
);

has scheme => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http',
);

has ssl_options => (
    is      => 'ro',
    isa     => 'HashRef',
    deafult => sub { +{} },
);

################################################################################
################################################################################

sub _build_yahc {
    my ($self) = @_;
    my ($yahc, $yahc_storage) = YAHC->new();

    $self->yahc_storage($yahc_storage);
    return $yahc;
}

################################################################################
################################################################################

sub send_http_request {
    my ($self, $request) = @_;

    my $ponapi_response;

    my $callback = sub {
        my ($conn) = @_;
        my $response = $conn->{response};
        $ponapi_response = {
            status => $response->{status},
            head   => $response->{head},
            body   => $response->{body},
        };
    };

    local $request->{callback} = $callback;
    local $request->{scheme} = $self->scheme;
    local $request->{ssl_options} = $self->ssl_options;

    my $yahc = $self->yahc;

    $yahc->request($request);
    $yahc->run();

    return $ponapi_response;
}

################################################################################
################################################################################

sub before_request { }

################################################################################
################################################################################

sub after_request { }

################################################################################
################################################################################

no Moose;
__PACKAGE__->meta->make_immutable();

1;

################################################################################
################################################################################
