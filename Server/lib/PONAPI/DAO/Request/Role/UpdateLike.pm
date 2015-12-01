package PONAPI::DAO::Request::Role::UpdateLike;

use Moose::Role;
use PONAPI::DAO::Constants;

has 'respond_to_updates_with_200' => (
    is  => 'ro',
    isa => 'Bool',
);

sub _verify_update_response {
    my ($self, $repo, $ret, @extra) = @_;

    die "update-like operation returned an unexpected value"
        unless exists $PONAPI_UPDATE_RETURN_VALUES{$ret};
    
    my $doc = $self->document;
    return if $doc->has_errors or $doc->has_status;

    if ( $self->respond_to_updates_with_200 ) {
        $doc->set_status(200);
        return $repo->retrieve(
            type     => $self->type,
            id       => $self->id,
            document => $doc,
        ) if $ret == PONAPI_UPDATED_EXTENDED;
    }
    else {
        $doc->set_status(202);
    }
    
    return 1;
};

override _add_success_meta => sub {
    my ($self, $return_status) = @_;

    my $resource = $self->_get_resource_for_meta;

    my $message = "successfully modified $resource";
    if ( $return_status == PONAPI_UPDATED_NOTHING ) {
        $self->document->set_status(204);
        $message = "modified nothing for $resource"
    }

    $self->document->add_meta( message => $message );
};

no PONAPI::DAO::Constants;
no Moose::Role; 1;
