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
                author => { type => "people", id => 88 },
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

## TODO:
my $todo = PONAPI::Builder::Document->new
    ->add_meta( message => "not implemented yet" )
    ->build;

sub retrieve_relationship { return $todo }
sub update                { return $todo }
###

sub retrieve_all {
    my ( $class, %args ) = @_;
    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );

    my $type = $args{type};

    unless ( exists $data{$type} ) {
        $doc->raise_error({ message => "type doesn't exist" });
        return $doc->build;
    }

    my $id_filter = exists $args{filter}{id} ? delete $args{filter}{id} : undef;

    my @ids = $id_filter
        ? grep { exists $data{$type}{$_} } @{ $id_filter }
        : keys %{ $data{$type} };

    # TODO: apply other filters

    _add_resource( $doc, $type, $_, $args{include} ) for @ids;

    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub retrieve {
    my ( $class, %args ) = @_;
    my $doc = PONAPI::Builder::Document->new();

    my $type = $args{type};

    unless ( exists $data{$type} ) {
        $doc->raise_error( { message => "type doesn't exist" } );
        return $doc->build;
    }

    my $id = $args{id};

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

sub create {
    my ( $class, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();

    my $type = ( $args{type} ||= undef );
    my $data = ( $args{data} ||= undef );

    if ( !$type ) {
        $doc->raise_error({ message => "can't create a resource without a 'type'" });
        return $doc->build;
    }

    if ( !$data and ref($data) eq 'HASH' ) {
        $doc->raise_error({ message => "can't create a resource without data" });
        return $doc->build;
    }

    $doc->add_meta( message => "successfully created the resource: $type => " . encode_json($data) );
    return $doc->build;
}

sub del {
    my ( $class, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();

    my $type = ( $args{type} ||= undef );
    my $id   = ( $args{id} ||= undef );

    if ( !$type ) {
        $doc->raise_error({ message => "can't create a resource without a 'type'" });
        return $doc->build;
    }

    if ( !$id ) {
        $doc->raise_error({ message => "can't create a resource without an 'id'" });
        return $doc->build;
    }

    $doc->add_meta( message => "successfully deleted the resource /$type/$id" );
    return $doc->build;
}


1;
