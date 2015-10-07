package PONAPI::DAO;
use Moose;

use PONAPI::DAO::Repository;
use PONAPI::Builder::Document;

has 'repository' => (
    is       => 'ro',
    does     => 'PONAPI::DAO::Repository',
    required => 1,
);

sub retrieve_all {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );
    eval {
        $self->repository->retrieve_all(
            document => $doc,
            type     => $args{type},
            includes => $args{include},
            fields   => $args{fields},
        );
        1;
    } or do {
        return _error( "$@" );
    };    

    # XXX:
    # should this really be here? 
    # I know we discussed it, but 
    # this feels wrong. 
    # - SL 
    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub retrieve {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->retrieve(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
            includes => $args{include},
            fields   => $args{fields},
        );
        1;
    } or do {
        return _error( "$@" );
    };   

    # XXX:
    # should this really be here? 
    # I know we discussed it, but 
    # this feels wrong. 
    # - SL 
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
        $self->repository->retrieve_relationships(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
            rel_type => $args{rel_type},
            rel_only => 1,
        );
        1;
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
        $self->repository->retrieve_by_relationship(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
            rel_type => $args{rel_type},
            rel_only => 0,
        );
        1;
    } or do {
        return _error( "$@" );
    };    
    return $doc->build;
}

sub create {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->create(
            document => $doc,
            type     => $args{type},
            id       => $args{id}, # optional ...
            data     => $args{data},
        );
        1;
    } or do {
        return _error( "$@" );
    };
    $doc->add_meta( message => "successfully created the resource: " . $args{type} . " => " . encode_json($args{data}) );
    return $doc->build;
}

sub update {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->update(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
            data     => $args{data},
        );
        1;
    } or do {
        return _error( "$@" );
    };        
    $doc->add_meta( message => "successfully updated the resource /" . $args{type} . "/" . $args{id} . " => " . encode_json($args{data}) );
    return $doc->build;
}

sub delete : method {
    my ( $self, %args ) = @_;

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->delete(
            document => $doc,
            type     => $args{type},
            id       => $args{id},
        );
        1;
    } or do {
        return _error( "$@" );
    };
    $doc->add_meta( message => "successfully deleted the resource /" . $args{type} . "/" . $args{id} );
    return $doc->build;
}

sub _error {
    PONAPI::Builder::Document->new()->raise_error({ message => shift })->build;
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;
