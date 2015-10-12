package PONAPI;

use Dancer2;

use Dancer2::Plugin::JSONAPI::MediaType;
use Dancer2::Plugin::JSONAPI::Params;
use Dancer2::Plugin::PONAPI::Repository;

set serializer => 'JSON';


# no ID
prefix '/:resource_type' => sub {
    # Retrieve all resources for type
    get '' => sub {
        DAO->retrieve_all(
            type     => route_parameters->get('resource_type'),
            fields   => query_parameters->get('fields'),
            filter   => query_parameters->get('filter'),
            page     => query_parameters->get('page'),
            include  => query_parameters->get_all('include'),
        );
    };

    # Create new resource(s)
    post '' => sub {
        DAO->create(
            type     => route_parameters->get('resource_type'),
            data     => body_parameters->get('data'),
        );
    };

};

# required ID
prefix '/:resource_type/:resource_id' => sub {

    # Retrieve a single resource
    get '' => sub {
        DAO->retrieve(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            fields   => query_parameters->get('fields'),
            include  => query_parameters->get_all('include'),
            page     => query_parameters->get('page'),
        );
    };

    # Retrieve related resources indirectly
    get '/:relationship_type' => sub {
        DAO->retrieve_by_relationship(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
            fields   => query_parameters->get('fields'),
            filter   => query_parameters->get('filter'),
            include  => query_parameters->get_all('include'),
            page     => query_parameters->get('page'),
        );
    };

    # Retrieve relationships for a single resource by type
    get '/relationships/:relationship_type' => sub {
        DAO->retrieve_relationships(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
#            filter   => query_parameters->get('filter'),
            page     => query_parameters->get('page'),
        );
    };

    # Update a single resource
    patch '' => sub {
        DAO->update(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            data     => body_parameters->get('data'),
        );
    };

    # Delete a single resource
    del '' => sub {
        DAO->delete(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
        );
    };

    # Delete a relationship for a single resource
    del '/relationships/:relationship_type' => sub {
        DAO->delete(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
        );
    };

};


1;

__END__
