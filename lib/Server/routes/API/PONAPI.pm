package API::PONAPI;

use Dancer2;

use API::PONAPI::Hooks;

use PONAPI::Builder::Document;

set serializer => 'JSON';

##### DAL MOCKUP (very incomplete)
{
    package DAL;

    my $todo = PONAPI::Builder::Document->new
        ->add_meta( message => "not implemented yet" )
        ->build;

    sub retrieve_all {
        my ( $class, %args ) = @_;

        # fetch the resources data (here we have $args{type})

        my $b = PONAPI::Builder::Document->new( is_collection => 1 );
        $b->add_resource( type => $args{type}, id => 1 );
        $b->add_resource( type => $args{type}, id => 2 );
        $b->add_resource( type => $args{type}, id => 3 );

        return $b->build;
    }

    sub retrieve {
        my ( $class, %args ) = @_;

        # fetch the resource data (here we have $args{type} & $args{id})

        my $b = PONAPI::Builder::Document->new();
        $b->add_resource( type => $args{type}, id => $args{id} )
            -> add_attributes( an => "attribute" );

        $b->add_links( self => "https://www.booking.com" );

        return $b->build;
    }

    sub retrieve_relationship { return $todo }

    sub create { return $todo }
    sub update { return $todo }
    sub del    { return $todo }

    1;
}
############################################################################################


# no ID
prefix '/:resource_type' => sub {

    # Retrieve all resources for type
    get '' => sub {
        return DAL->retrieve_all(
            type     => route_parameters->get('resource_type'),
            include  => query_parameters->get_all('include'),
            fields   => query_parameters->get_all('fields'),
            page     => query_parameters->get_all('page'),
        );
    };

    # Create new resource(s)
    post '' => sub {
        return DAL->create(
            type     => route_parameters->get('resource_type'),
            data     => body_parameters->get('data'),
        );
    };

};

# required ID
prefix '/:resource_type/:resource_id' => sub {

    # Retrieve a single resource
    get '' => sub {
        return DAL->retrieve(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            include  => query_parameters->get_all('include'),
            fields   => query_parameters->get_all('fields'),
            page     => query_parameters->get_all('page'),
        );
    };

    # Retrieve a related resource indirectly
    get '/:relationship_type' => sub {
        return DAL->retrieve(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
            include  => query_parameters->get_all('include'),
            fields   => query_parameters->get_all('fields'),
            page     => query_parameters->get_all('page'),
        );
    };

    # Retrieve a relationship for a single resource
    get '/relationships/:relationship_type' => sub {
        return DAL->retrieve_relationship(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
            # include  => query_parameters->get_all('include'),
            # fields   => query_parameters->get_all('fields'),
            page     => query_parameters->get_all('page'),
        );
    };

    # Update a single resource
    patch '' => sub {
        return DAL->update(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            data     => body_parameters->get('data'),
        );
    };

    # Delete a single resource
    del '' => sub {
        return DAL->del(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
        );
    };

    # Delete a relationship for a single resource
    del '/relationships/:relationship_type' => sub {
        return DAL->del(
            type     => route_parameters->get('resource_type'),
            id       => route_parameters->get('resource_id'),
            rel_type => route_parameters->get('relationship_type'),
        );
    };

};


1;
