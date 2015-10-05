package DAL::Mockup;

use strict;
use warnings;

use JSON::XS qw( encode_json );

use PONAPI::Builder::Document;

##################################
my %data = (
    books => {},

    articles => {
        1 => {
            attributes => {
                title   => "JSON API paints my bikeshed!",
                body    => "The shortest article. Ever.",
                created => "2015-05-22T14:56:29.000Z",
                updated => "2015-05-22T14:56:28.000Z",
            },
            relationships => {
                author => { type => "people", id => 42 },
            },
        },

        2 => {
            attributes => {
                title   => "A second title",
                body    => "The 2nd shortest article. Ever.",
                created => "2015-06-22T14:56:29.000Z",
                updated => "2015-06-22T14:56:28.000Z",
            },
            relationships => {
                author   => { type => "people", id => 88 },
                comments => [
                    { type => "comments", id => 5 },
                    { type => "comments", id => 12 },
                ],
            },
        },

        3 => {
            attributes => {
                title   => "a third one",
                body    => "The 3rd shortest article. Ever.",
                created => "2015-07-22T14:56:29.000Z",
                updated => "2015-07-22T14:56:28.000Z",
            },
            relationships => {
                author => { type => "people", id => 91 },
            },
        },
    },

    comments => {
        5  => {
            attributes => {
                body => "First!",
            },
            relationships => {
                articles => { type => "articles", id => 2 },
            },
        },
        12 => {
            attributes => {
                body => "I like XML better",
            },
            relationships => {
                articles => { type => "articles", id => 2 },
            },
        },
    },

    people => {
        42 => {
            attributes => {
                name   => "John",
                age    => 80,
                gender => "male",
            },
        },

        88 => {
            attributes => {
                name   => "Jimmy",
                age    => 18,
                gender => "male",
            },
        },

        91 => {
            attributes => {
                name   => "Diana",
                age    => 30,
                gender => "female",
            },
        },
    },
);
##################################

sub retrieve_all {
    my ( $class, %args ) = @_;

    my $type = $args{type};

    exists $data{$type} or return _error( "type $type doesn't exist" );

    my $id_filter = exists $args{filter}{id} ? delete $args{filter}{id} : undef;

    my @ids = $id_filter
        ? grep { exists $data{$type}{$_} } @{ $id_filter }
        : keys %{ $data{$type} };

    # TODO: apply other filters

    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );
    _add_resource( $doc, $type, $_, $args{include} ) for @ids;

    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub retrieve {
    my ( $class, %args ) = @_;
    my $doc = PONAPI::Builder::Document->new();

    my ( $type, $id ) = @args{qw< type id >};

    exists $data{$type} or return _error( "type $type doesn't exist" );

    unless ( exists $data{$type}{$id} ) {
        $doc->add_null_resource(undef);
        return $doc->build;
    }

    _add_resource( $doc, $type, $id, $args{include} );

    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub _add_resource {
    my ( $doc, $type, $id, $include ) = @_;

    my $resource = $doc->add_resource( type => $type, id => $id );

    $resource->add_attributes( %{ $data{$type}{$id}{attributes} } )
        if keys %{ $data{$type}{$id}{attributes} };

    my %relationships = %{ $data{$type}{$id}{relationships} };
    for my $k ( keys %relationships ) {
        $resource->add_relationship( $k => $relationships{$k} );

        my ( $t, $i ) = @{ $relationships{$k} }{qw< type id >};

        if ( $include and exists $include->{$k} and exists $data{$t}{$i} ) {
            my $included = $doc->add_included( type => $t, id => $i );
            $included->add_attributes( %{ $data{$t}{$i}{attributes} } )
                if exists $data{$t}{$i}{attributes};
        }
    }
}

sub retrieve_relationships {
    my ( $class, %args ) = @_;

    my ( $type, $id, $rel_type ) = @args{qw< type id rel_type >};

    exists $data{$type}      or return _error( "type $type doesn't exist" );
    exists $data{$type}{$id} or return _error( "id $id doesn't exist" );
    exists $data{$type}{$id}{relationships} or return _error( "resource has no relationships" );

    my $relationships = $data{$type}{$id}{relationships}{$rel_type};
    $relationships or return _error( "relationships type $rel_type doesn't exist" );

    my $collection = ref($relationships) eq 'ARRAY' ? 1 : 0;
    my $doc = PONAPI::Builder::Document->new( is_collection => $collection );
    if ( $collection ) {
        $doc->add_resource( %{$_} ) for @{$relationships};
    } else {
        $doc->add_resource( %{$relationships} );
    }
    return $doc->build;
}

sub retrieve_by_relationship {
    my ( $class, %args ) = @_;

    my ( $type, $id, $rel_type ) = @args{qw< type id rel_type >};

    exists $data{$type}      or return _error( "type $type doesn't exist" );
    exists $data{$type}{$id} or return _error( "id $id doesn't exist" );
    exists $data{$type}{$id}{relationships} or return _error( "resource has no relationships" );

    my $relationships = $data{$type}{$id}{relationships}{$rel_type};
    $relationships or return _error( "relationships type $rel_type doesn't exist" );

    # TODO: apply filters/etc.

    my $collection = ref($relationships) eq 'ARRAY' ? 1 : 0;
    my $doc = PONAPI::Builder::Document->new( is_collection => $collection );
    if ( $collection ) {
        _add_resource( $doc, $_->{type}, $_->{id} ) for @{$relationships};
    } else {
        _add_resource( $doc, $relationships->{type}, $relationships->{id} );
    }
    return $doc->build;
}

sub create {
    my ( $class, %args ) = @_;

    my ( $type, $data ) = @args{qw< type data >};

    $type or return _error( "type $type doesn't exist" );
    $data and ref($data) eq 'HASH' or return _error( "can't create a resource without data" );

    # TODO: create the resource

    my $doc = PONAPI::Builder::Document->new();

    $doc->add_meta( message => "successfully created the resource: $type => " . encode_json($data) );
    return $doc->build;
}

sub update {
    my ( $class, %args ) = @_;

    my ( $type, $id, $data ) = @args{qw< type id data >};

    $type or return _error( "can't update a resource without a 'type'" );
    $type or return _error( "can't update a resource without an 'id'"  );
    $type or return _error( "can't update a resource without data"     );

    # TODO: update the resource

    my $doc = PONAPI::Builder::Document->new();
    $doc->add_meta( message => "successfully updated the resource /$type/$id => " . encode_json($data) );
    return $doc->build;
}

sub del {
    my ( $class, %args ) = @_;

    my ( $type, $id ) = @args{qw< type id >};

    $type or return _error( "can't delete a resource without a 'type'" );
    $type or return _error( "can't delete a resource without an 'id'"  );

    # TODO: delte the resource

    my $doc = PONAPI::Builder::Document->new();
    $doc->add_meta( message => "successfully deleted the resource /$type/$id" );
    return $doc->build;
}

sub _error {
    my $doc = PONAPI::Builder::Document->new();
    $doc->raise_error({ message => shift });
    return $doc->build;
}


1;
