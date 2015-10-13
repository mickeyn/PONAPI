package PONAPI::DAO::Repository::Mock;
use Moose;

use YAML::XS    ();
use Path::Class ();

use MooseX::Types::Path::Class;

with 'PONAPI::DAO::Repository';

has 'data_dir' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

has 'rel_spec' => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub {
        return +{
            comments => {
                article => { has_one => 'articles' },
            },
            articles => {
                author   => { has_one  => 'people'   },
                comments => { has_many => 'comments' },
            }
        }
    },
);

has 'data' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $dir  = $self->data_dir;

        my $articles = YAML::XS::Load( scalar $dir->file('articles.yml')->slurp );
        my $comments = YAML::XS::Load( scalar $dir->file('comments.yml')->slurp );
        my $people   = YAML::XS::Load( scalar $dir->file('people.yml'  )->slurp );

        return +{
            articles => $articles,
            comments => $comments,
            people   => $people,
        }
    },
);

# NOTE:
# force the data to be built
# instead of letting the lazy
# stuff build it later on.
# - SL
sub BUILD { $_[0]->data }

sub has_type {
    my ( $self, $type ) = @_;
    !! exists $self->data->{ $type };
}

sub has_relationship {
    my ( $self, $type, $rel_name ) = @_;

    my $spec = $self->rel_spec;
    return 0 unless exists $spec->{ $type };
    return 0 unless exists $spec->{ $type }->{ $rel_name };
    return $spec->{ $type }->{ $rel_name };
}

sub retrieve_all {
    my ( $self, %args ) = @_;

    my ( $doc, $type, $filter, $include ) = @args{qw< document type filter include >};

    exists $self->data->{$type} or return $self->_error( $doc, "type $type doesn't exist" );

    my $ids = $self->_get_ids_filtered( $type, $filter );

    for ( @{$ids} ) {
        $self->_add_resource({
            type     => $type,
            id       => $_,
            document => $doc,
            include  => $include,
        });
    }
}

sub retrieve {
    my ( $self, %args ) = @_;

    my ( $doc, $type, $id, $include ) = @args{qw< document type id include >};

    exists $self->data->{$type} or return $self->_error( $doc, "type $type doesn't exist" );

    unless ( exists $self->data->{$type}{$id} ) {
        $doc->add_null_resource();
        return;
    }

    $self->_add_resource({
        document => $doc,
        type     => $type,
        id       => $id,
        include  => $include,
    });
}

sub retrieve_relationships {
    my ( $self, %args ) = @_;

    my $data = $self->data;
    my ( $doc, $type, $id, $rel_type ) = @args{qw< document type id rel_type >};

    exists $data->{$type}      or return $self->_error( $doc, "type $type doesn't exist" );
    exists $data->{$type}{$id} or return $self->_error( $doc, "id $id doesn't exist" );
    exists $data->{$type}{$id}{relationships} or return $self->_error( $doc, "resource has no relationships" );

    my $relationships = $data->{$type}{$id}{relationships}{$rel_type};
    $relationships or return $self->_error( $doc, "relationships type $rel_type doesn't exist" );

    my @rels = ref $relationships eq 'ARRAY' ? @{$relationships} : $relationships;
    for ( @rels ) {
        $self->_add_resource({
            type            => $_->{type},
            id              => $_->{id},
            document        => $doc,
            identifier_only => 1,
        });
    }
}

sub retrieve_by_relationship {
    my ( $self, %args ) = @_;

    my $data = $self->data;
    my $doc = $args{document};

    # these need to be removed from %args:
    my $id       = delete $args{id};
    my $type     = delete $args{type};
    my $rel_type = delete $args{rel_type};

    exists $data->{$type}      or return $self->_error( $doc, "type $type doesn't exist" );
    exists $data->{$type}{$id} or return $self->_error( $doc, "id $id doesn't exist" );
    exists $data->{$type}{$id}{relationships}
        or return $self->_error( $doc, "resource has no relationships" );

    my $rels = $data->{$type}{$id}{relationships}{$rel_type};
    ref $rels or return $self->_error( $doc, "resource doesn't have the requested relationship" );

    my @rels = ref $rels eq 'ARRAY' ? @{$rels} : $rels;
    for ( @rels ) {
        $self->retrieve( type => $_->{type}, id => $_->{id}, %args );
    }
}

sub create {
    my ( $self, %args ) = @_;

    my ( $doc, $type, $data ) = @args{qw< document type data >};

    $type or return $self->_error( $doc, "type $type doesn't exist" );
    $data and ref $data eq 'HASH' or return $self->_error( $doc, "can't create a resource without data" );

    # TODO: create the resource
}

sub update {
    my ( $self, %args ) = @_;

    my ( $doc, $type, $id, $data ) = @args{qw< document type id data >};

    $type or return $self->_error( $doc, "can't update a resource without a 'type'" );
    $id   or return $self->_error( $doc, "can't update a resource without an 'id'"  );
    $data or return $self->_error( $doc, "can't update a resource without data"     );

    # TODO: update the resource
}

sub delete : method {
    my ( $self, %args ) = @_;

    my ( $doc, $type, $id ) = @args{qw< document type id >};

    $type or return $self->_error( $doc, "can't delete a resource without a 'type'" );
    $id   or return $self->_error( $doc, "can't delete a resource without an 'id'"  );

    # TODO: delte the resource
}

## --------------------------------------------------------

sub _get_ids_filtered {
    my ( $self, $type, $filters ) = @_;

    my $data = $self->data;

    my @ids;

    # id filter

    my $id_filter = exists $filters->{id} ? delete $filters->{id} : undef;
    @ids = $id_filter
        ? grep { exists $data->{$type}{$_} } @{ $id_filter }
        : keys %{ $data->{$type} };

    # attribute filters
    for my $f ( keys %{ $filters } ) {
        @ids = grep {
            my $att = $data->{$type}{$_}{attributes}{$f};
            grep { $att eq $_ } @{ $filters->{$f} }
        } @ids;
    }

    return \@ids;
}

sub _add_resource {
    my ( $self, $args ) = @_;
    ref $args eq 'HASH' or die "_add_resource: args must be a hashref";

    my ( $doc, $type, $id, $identifier_only, $include ) =
        @{$args}{qw< document type id identifier_only include >};

    my $resource = $doc->add_resource( type => $type, id => $id );
    return if $identifier_only;

    my $rec_info = $self->data->{$type}{$id};
    my $has_attributes    = exists $rec_info->{attributes};
    my $has_relationships = exists $rec_info->{relationships};
    my $has_include       = ref $include eq 'ARRAY';

    $resource->add_attributes( %{ $rec_info->{attributes} } ) if $has_attributes;

    return unless $has_relationships;

    # add relationship resource identifiers
    for my $k ( keys %{ $rec_info->{relationships} } ) {
        my $v = $rec_info->{relationships}{$k};

        $resource->add_relationship( $k => $v );

        next unless $has_include and grep { $_ eq $k } @{$include};

        # add related resources to 'included'
        my @rels = ref $v eq 'ARRAY' ? @{$v} : $v;
        for ( @rels ) {
            my ( $t, $i ) = @{$_}{qw< type id >};

            if ( my $rec = $self->data->{$t}{$i} ) {
                my $included = $doc->add_included( type => $t, id => $i );
                $included->add_attributes( %{ $rec->{attributes} } )
                    if exists $rec->{attributes};
            }
        }
    }
}

sub _error {
    my ( $self, $doc, $message ) = @_;
    $doc->raise_error({ message => $message });
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
