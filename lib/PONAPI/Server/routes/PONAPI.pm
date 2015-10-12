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
            fields   => jsonapi_parameters->{fields},
            filter   => jsonapi_parameters->{filter},
            page     => jsonapi_parameters->{page},
            include  => jsonapi_parameters->{include},
        );
    };

    # Create new resource(s)
    post '' => sub {
        DAO->create(
            type     => route_parameters->get('resource_type'),
            data     => jsonapi_parameters->{resource_type},
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
            fields   => jsonapi_parameters->{fields},
            include  => jsonapi_parameters->{include},
            page     => jsonapi_parameters->{page},
        );
    };

    # Retrieve related resources indirectly
    get '/:relationship_type' => sub {
        DAO->retrieve_by_relationship(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
            fields   => jsonapi_parameters->{fields},
            filter   => jsonapi_parameters->{filter},
            include  => jsonapi_parameters->{include},
            page     => jsonapi_parameters->{page},
        );
    };

    # Retrieve relationships for a single resource by type
    get '/relationships/:relationship_type' => sub {
        DAO->retrieve_relationships(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
#            filter   => jsonapi_parameters->{filter},
            page     => jsonapi_parameters->{page},
        );
    };

    # Update a single resource
    patch '' => sub {
        DAO->update(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            data     => jsonapi_parameters->{data},
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
