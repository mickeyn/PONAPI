package PONAPI;

use Dancer2;

use PONAPI::Plugin::MediaType;
use PONAPI::Plugin::Params;
use PONAPI::Plugin::Repository;

set serializer => 'JSON';


# no ID
prefix '/:resource_type' => sub {

    # Create new resource(s)
    post '' => sub { DAO->create( ponapi_parameters ) };

    # Retrieve all resources for type
    get ''  => sub { DAO->retrieve_all( ponapi_parameters ) };
};

# required ID
prefix '/:resource_type/:resource_id' => sub {

    # Retrieve a single resource
    get '' => sub { DAO->retrieve( ponapi_parameters ) };

    # Retrieve related resources indirectly
    get '/:relationship_type' => sub {
        DAO->retrieve_by_relationship( ponapi_parameters )
    };

    # Retrieve relationships for a single resource by type
    get '/relationships/:relationship_type' => sub {
        DAO->retrieve_relationships( ponapi_parameters );
    };

    # Update a single resource
    patch '' => sub { DAO->update( ponapi_parameters ) };

    # Delete a single resource
    del '' => sub { DAO->delete( ponapi_parameters ) };

    # Delete a relationship for a single resource
    del '/relationships/:relationship_type' => sub {
        DAO->delete( ponapi_parameters );
    };
};


1;

__END__
