package PONAPI;

use Dancer2;

use PONAPI::Plugin::MediaType;
use PONAPI::Plugin::Params;
use PONAPI::Plugin::Repository;

set serializer => 'JSON';

sub dao_action {
    my $action = shift;
    return sub {
        my ( $status, $content ) = DAO->$action( ponapi_parameters );
        response->status($status);
        return $content;
    };
}

# no ID
prefix '/:resource_type' => sub {

    # Create new resource(s)
    post '' => dao_action('create');

    # Retrieve all resources for type
    get ''  => dao_action('retrieve_all');
};

# required ID
prefix '/:resource_type/:resource_id' => sub {

    # Create relationship(s) for a single resource
    post '/relationships/:relationship_type' => dao_action('create_relationships');

    # Retrieve a single resource
    get '' => dao_action('retrieve');

    # Retrieve related resources indirectly
    get '/:relationship_type' => dao_action('retrieve_by_relationship');

    # Retrieve relationships for a single resource by type
    get '/relationships/:relationship_type' => dao_action('retrieve_relationships');

    # Update a single resource
    patch '' => dao_action('update');

    # Update relationships of a resource
    patch '/relationships/:relationship_type' => dao_action('update_relationships');

    # Delete a single resource
    del '' => dao_action('delete');

    # Delete relationship(s) for a single resource
    del '/relationships/:relationship_type' => dao_action('delete_relationships');
};


1;

__END__
