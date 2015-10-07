package PONAPI::DAL;
use Moose;

use PONAPI::DAL::Schema;
use PONAPI::Builder::Document;

has 'schema' => (
    is       => 'ro',
    does     => 'PONAPI::DAL::Schema',
    required => 1,
);

sub retrieve_all {
    my ( $self, %args ) = @_;

    my $type = $args{type};

    exists $data{$type} or return _error( "type $type doesn't exist" );

    my $id_filter = exists $args{filter}{id} ? delete $args{filter}{id} : undef;

    my @ids = $id_filter
        ? grep { exists $data{$type}{$_} } @{ $id_filter }
        : keys %{ $data{$type} };

    # TODO: apply other filters

    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );

    eval {
        $self->schema->retrieve_all(
            document => $doc,
            type     => $type,
            ids      => \@ids,
            includes => $args{include}
        );
    } or do {
        return _error( "$@" );
    };    

    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub retrieve {
    my ( $self, %args ) = @_;

    my ( $type, $id ) = @args{qw< type id >};
    exists $data{$type} or return _error( "type $type doesn't exist" );

    my $doc = PONAPI::Builder::Document->new();

    unless ( exists $data{$type}{$id} ) {
        $doc->add_null_resource(undef);
        return $doc->build;
    }

    eval {
        $self->schema->retrieve(
            document => $doc,
            type     => $type,
            id       => $id,
            includes => $args{include}
        );
    } or do {
        return _error( "$@" );
    };   

    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub retrieve_relationships   { 
    my ($self, %args) = @_;

    # NOTE: 
    # make everything a collection for
    # now, we can fix this later with
    # the type metadata
    # - SL
    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );
    eval {
        $self->schema->retrieve_relationships(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
            rel_type => $args{rel_type},
            rel_only => 1,
        );
    } or do {
        return _error( "$@" );
    };    
    return $doc->build;
}

sub retrieve_by_relationship { 
    my ($self, %args) = @_;

    # NOTE: 
    # make everything a collection for
    # now, we can fix this later with
    # the type metadata
    # - SL
    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );
    eval {
        $self->schema->retrieve_by_relationship(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
            rel_type => $args{rel_type},
            rel_only => 0,
        );
    } or do {
        return _error( "$@" );
    };    
    return $doc->build;
}

sub create {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->schema->create(
            document => $doc,
            type     => $args{type},
            id       => $args{id}, # optional ...
            data     => $args{data},
        );
    } or do {
        return _error( "$@" );
    };
    $doc->add_meta( message => "successfully created the resource: $type => " . encode_json($data) );
    return $doc->build;
}

sub update {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->schema->update(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
            data     => $args{data},
        );
    } or do {
        return _error( "$@" );
    };        
    $doc->add_meta( message => "successfully updated the resource /$type/$id => " . encode_json($data) );
    return $doc->build;
}

sub delete : method {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->schema->delete(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
        );
    } or do {
        return _error( "$@" );
    };
    $doc->add_meta( message => "successfully deleted the resource /$type/$id" );
    return $doc->build;
}

sub _error {
    PONAPI::Builder::Document->new()->raise_error({ message => shift })->build;
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;
