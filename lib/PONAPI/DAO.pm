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
    my $self = shift;
    my %args = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    my $doc = PONAPI::Builder::Document->new( is_collection => 1 );
    eval {
        $self->repository->retrieve_all(
            document => $doc,
            %args
        );
        1;
    } or do {
        # NOTE: this probably needs to be more sophisticated - SL
        warn "$@";
        $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
    };

    # XXX:
    # this also gets passed to the repository
    # and we add it here, we might want to
    # think about this a bit. It is fine for
    # now, but should be revisited.
    # - SL
    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub retrieve {
    my $self = shift;
    my %args = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->retrieve(
            document => $doc,
            %args
        );
        1;
    } or do {
        # NOTE: this probably needs to be more sophisticated - SL
        warn "$@";
        $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
    };

    # XXX:
    # see comment in &retrieve_all
    # - SL
    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub retrieve_relationships {
    my $self = shift;
    my %args = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # TODO:
    # add some (more) type checking using
    # has_type and has_relationship
    # - SL

    my $doc;
    if ( my $rel = $self->repository->has_relationship( $args{type}, $args{rel_type} ) ) {
        $doc = PONAPI::Builder::Document->new(
            is_collection => $rel->{has_many} ? 1 : 0
        );
        eval {
            $self->repository->retrieve_relationships(
                document => $doc,
                %args
            );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };
    }
    else {
        $doc = PONAPI::Builder::Document->new;
        $doc->raise_error({
            message => 'Relationship (' . $args{rel_type} . ') not found for type(' . $args{type} . ')'
        })
    }

    return $doc->build;
}

sub retrieve_by_relationship {
    my $self = shift;
    my %args = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # TODO:
    # add some (more) type checking using
    # has_type and has_relationship
    # - SL

    my $doc;
    if ( my $rel = $self->repository->has_relationship( $args{type}, $args{rel_type} ) ) {
        $doc = PONAPI::Builder::Document->new(
            is_collection => $rel->{has_many} ? 1 : 0
        );
        eval {
            $self->repository->retrieve_by_relationship(
                document => $doc,
                %args,
            );
            1;
        } or do {
            # NOTE:  this probably needs to be more sophisticated - SL
            warn "$@";
            $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
        };
    }
    else {
        $doc = PONAPI::Builder::Document->new;
        $doc->raise_error({
            message => 'Relationship (' . $args{rel_type} . ') not found for type(' . $args{type} . ')'
        })
    }

    my @fields = exists $args{fields} ? ( fields => $args{fields} ) : ();
    return $doc->build( @fields );
}

sub create {
    my $self = shift;
    my %args = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->create(
            document => $doc,
            %args
        );
        $doc->add_meta(
            message => "successfully created the resource: "
                     . $args{type}
                     . " => "
                     . encode_json($args{data})
        );
        1;
    } or do {
        # NOTE: this probably needs to be more sophisticated - SL
        warn "$@";
        $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
    };
    return $doc->build;
}

sub update {
    my $self = shift;
    my %args = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->update(
            document => $doc,
            %args
        );
        $doc->add_meta(
            message => "successfully updated the resource /"
                     . $args{type}
                     . "/"
                     . $args{id}
                     . " => "
                     . encode_json( $args{data} )
        );
        1;
    } or do {
        # NOTE: this probably needs to be more sophisticated - SL
        warn "$@";
        $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
    };
    return $doc->build;
}

sub delete : method {
    my $self = shift;
    my %args = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # TODO:
    # add some type checking using
    # has_type and has_relationship
    # - SL

    my $doc = PONAPI::Builder::Document->new();
    eval {
        $self->repository->delete(
            document => $doc,
            %args
        );
        $doc->add_meta(
            message => "successfully deleted the resource /"
                     . $args{type}
                     . "/"
                     . $args{id}
        );
        1;
    } or do {
        # NOTE: this probably needs to be more sophisticated - SL
        warn "$@";
        $doc->raise_error({ message => 'A fatal error has occured, please check server logs' });
    };
    return $doc->build;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;
