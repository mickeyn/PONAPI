package PONAPI::Server::ConfigReader;

use Moose;

use PONAPI::DAO;

use Moose::Util::TypeConstraints;
use Path::Class::Dir;

class_type 'Path::Class::Dir';
coerce 'Path::Class::Dir',
    from 'Str',
    via { Path::Class::Dir->new($_) };

has dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_conf',
);

sub _build_conf {
    my $self = shift;
    return YAML::XS::Load( scalar $self->dir->file('server.yml')->slurp );
}

sub read_config {
    my $self = shift;

    $self->_set_server_json_api_version;

    $self->_set_server_sorting;
    $self->_set_server_send_header;
    $self->_set_server_self_link;
    $self->_set_server_relative_links;
    $self->_load_repository;

    $self->{'ponapi.mediatype'} = 'application/vnd.api+json';
    $self->{'ponapi.qr_mediatype'} = qr{application/vnd\.api\+json};

    return %{$self};
}

sub _set_server_respond_to_updates_status {
    my $self = shift;

    $self->{'ponapi.respond_to_updates_with_200'} =
        $self->config->{server}{respond_to_updates_with_200};
}

sub _set_server_sorting {
    my $self = shift;

    my $sort_allowed = $self->config->{server}{sort_allowed}
        // die "[PONAPI Server] server sorting configuration is missing";

    $self->{'ponapi.sort_allowed'} =
        ( grep { $sort_allowed eq $_ } qw< yes true 1 > ) ? 1 :
        ( grep { $sort_allowed eq $_ } qw< no false 0 > ) ? 0 :
        die "[PONAPI Server] server sorting is misconfigured";
}

sub _set_server_json_api_version {
    my $self = shift;

    my $spec_version = $self->config->{server}{spec_version}
        // die "[PONAPI Server] server JSON API version configuration is missing";

    $self->{'ponapi.spec_version'} = $spec_version;
}

sub _set_server_send_header {
    my $self = shift;

    $self->{'ponapi.spec_version'} = $self->config->{server}{spec_version}
        // die "[PONAPI Server] server spec version is not configured";

    $self->{'ponapi.send_version_header'} =
        ( grep { $self->config->{server}{send_version_header} eq $_ } qw< yes true 1 > ) ? 1 : 0;
}

sub _set_server_self_link {
    my $self = shift;

    $self->{'ponapi.doc_auto_self_link'} =
        ( grep { $self->config->{server}{send_document_self_link} eq $_ } qw< yes true 1 > ) ? 1 : 0;
}

sub _set_server_relative_links {
    my $self = shift;

    grep { $self->config->{server}{links_type} eq $_ } qw< relative full >
        or die "[PONAPI Server] server links_type is misconfigured";

    $self->{'ponapi.relative_links'} = $self->config->{server}{links_type};
}

sub _load_repository {
    my $self = shift;
    my $conf = $self->config->{repository};

    my $repository = Module::Runtime::use_module( $conf->{class} )->new( @{ $conf->{args} } )
        || die "[PONAPI Server] failed to create a repository object\n";

    $self->{'ponapi.DAO'} = PONAPI::DAO->new(
        repository => $repository,
        version    => $self->{'ponapi.spec_version'},
    );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
