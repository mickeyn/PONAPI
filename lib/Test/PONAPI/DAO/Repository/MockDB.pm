package Test::PONAPI::DAO::Repository::MockDB;
use Moose;

use DBI;
use SQL::Composer;

use Test::PONAPI::DAO::Repository::MockDB::Loader;

use Test::PONAPI::DAO::Repository::MockDB::Table::Articles;
use Test::PONAPI::DAO::Repository::MockDB::Table::People;
use Test::PONAPI::DAO::Repository::MockDB::Table::Comments;

with 'PONAPI::DAO::Repository';

has dbh => (
    is     => 'ro',
    isa    => 'DBI::db',
    writer => '_set_dbh'
);

has tables => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        return +{
            articles => Test::PONAPI::DAO::Repository::MockDB::Table::Articles->new,
            people   => Test::PONAPI::DAO::Repository::MockDB::Table::People->new,
            comments => Test::PONAPI::DAO::Repository::MockDB::Table::Comments->new,
        }
    }
);

sub BUILD {
    my ($self, $params) = @_;
    my $loader = Test::PONAPI::DAO::Repository::MockDB::Loader->new;
    $loader->load unless $params->{skip_data_load};
    $self->_set_dbh( $loader->dbh );
}

sub has_type {
    my ( $self, $type ) = @_;
    !! exists $self->tables->{$type};
}

sub has_relationship {
    my ( $self, $type, $rel_name ) = @_;
    if ( my $table = $self->tables->{$type} ) {
        my $relations = $table->RELATIONS;
        return !! exists $relations->{ $rel_name };
    }
    return 0;
}

sub retrieve_all {
    my ( $self, %args ) = @_;
    my $type = $args{type};

    my $filters = $self->_stmt_filters($type, $args{filter});

    my $stmt = SQL::Composer::Select->new(
        from    => $type,
        columns => $self->_stmt_columns(\%args),
        where   => [ %{ $filters } ],
    );

    $self->_add_resources( stmt => $stmt, %args );
}

sub retrieve {
    my ( $self, %args ) = @_;
    $args{filter}{id} = delete $args{id};
    return $self->retrieve_all(%args);
}

sub retrieve_relationships {
    my ( $self, %args ) = @_;
    my $doc = $args{document};

    my $rels = $self->_find_resource_relationships(%args)
        or return;

    return $doc->add_resource( %{ $rels->[0] } )
        if @{$rels} == 1;

    $doc->convert_to_collection;
    $doc->add_resource( %$_ ) for @{$rels};
}

sub retrieve_by_relationship {
    my ( $self, %args ) = @_;
    my ( $doc, $fields, $include ) = @args{qw< document fields include >};

    my $rels = $self->_find_resource_relationships(%args)
        or return;

    my $q_type = $rels->[0]{type};
    my $q_ids  = [ map { $_->{id} } @{$rels} ];

    my $stmt = SQL::Composer::Select->new(
        from    => $q_type,
        columns => $self->_stmt_columns({ type => $q_type, fields => $fields }),
        where   => [ id => $q_ids ],
    );

    $self->_add_resources(
        document              => $doc,
        stmt                  => $stmt,
        type                  => $q_type,
        fields                => $fields,
        include               => $include,
        convert_to_collection => 1,
    );
}

sub create {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $data ) = @args{qw< document type data >};

    my $stmt = SQL::Composer::Insert->new(
        into   => $type,
        values => [ %{ $data->{attributes} } ],
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error({ message => $errstr });

    return 1;
}

sub create_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    # TODO: check type can have To-Many relationships or error

    # TODO: add missing login

    return 1;
}

sub update {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $data ) = @args{qw< document type id data >};

    my $stmt = SQL::Composer::Update->new(
        table  => $type,
        values => [ %{ $data->{attributes} } ],
        where  => [ id => $id ],
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error({ message => $errstr });

    return 1;
}

sub update_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    # TODO: check type can have To-Many relationships or error

    # TODO: add missing login

    return 1;
}

sub delete : method {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id ) = @args{qw< document type id >};

    my $stmt = SQL::Composer::Delete->new(
        from  => $type,
        where => [ id => $id ],
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error({ message => $errstr });

    return 1;
}

sub delete_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    # TODO: check type can have To-Many relationships or error

    # TODO: add missing login

    return 1;
}


## --------------------------------------------------------

sub _add_resources {
    my ( $self, %args ) = @_;
    my ( $doc, $stmt, $type, $convert_to_collection ) = @args{qw< document stmt type convert_to_collection >};

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error({ message => $errstr });

    my $counter = 0;

    while ( my $row = $sth->fetchrow_hashref() ) {
        if ( $counter == 1 && $convert_to_collection ) {
            $doc->convert_to_collection;
        }
        my $id = delete $row->{id};
        my $rec = $doc->add_resource( type => $type, id => $id );
        $rec->add_attribute( $_ => $row->{$_} ) for keys %{$row};

        $self->_add_resource_relationships($rec, %args);
        $counter++;
    }

    $doc->has_resources or $doc->add_null_resource;
}

sub _add_resource_relationships {
    my ( $self, $rec, %args ) = @_;
    my $doc = $rec->find_root;
    my %include = map { $_ => 1 } @{ $args{include} };

    my $rels = $self->_fetchall_relationships(
        type     => $rec->type,
        id       => $rec->id,
        document => $doc,
        fields   => $args{fields},
    );
    $rels or return;

    for my $r ( keys %{$rels} ) {
        @{ $rels->{$r} } > 0 or next;

        $rec->add_relationship( $r, $_ ) for @{ $rels->{$r} };

        $self->_add_included(
            $rels->{$r}[0]{type},                   # included type
            +[ map { $_->{id} } @{ $rels->{$r} } ], # included ids
            %args                                   # filters / fields / etc.
        ) if exists $include{$r};
    }
}

sub _add_included {
    my ( $self, $type, $ids, %args ) = @_;
    my ( $doc, $filter, $fields ) = @args{qw< document filter fields >};

    my $filters = $self->_stmt_filters($type, $filter);

    my $stmt = SQL::Composer::Select->new(
        from    => $type,
        columns => $self->_stmt_columns({ type => $type, fields => $fields }),
        where   => [ id => $ids, %{ $filters } ],
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error({ message => $errstr });

    while ( my $inc = $sth->fetchrow_hashref() ) {
        my $id = delete $inc->{id};
        $doc->add_included( type => $type, id => $id )
            ->add_attributes( %{$inc} );
    }
}

sub _find_resource_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $rel_type ) = @args{qw< document rel_type >};

    my $rels = $self->_fetchall_relationships(%args)
        or return;

    return $rels->{$rel_type} if exists $rels->{$rel_type};

    $doc->add_null_resource();
    return;
}

sub _fetchall_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id, $doc ) = @args{qw< type id doc >};
    my %type_fields = map { $_ => 1 } @{ $args{fields}{$type} };
    my %ret;
    my @errors;

    for my $name ( keys %{ $self->tables->{$type}->RELATIONS } ) {
        next if keys %type_fields > 0 and !exists $type_fields{$name};

        my ( $rel_type, $rel_table ) =
            @{ $self->tables->{$type}->RELATIONS->{$name} }{qw< type rel_table >};

        my $stmt = SQL::Composer::Select->new(
            from    => $rel_table,
            columns => [ 'id_' . $rel_type ],
            where   => [ 'id_' . $type => $id ],
        );

        my ( $sth, $errstr ) = $self->_db_execute( $stmt );
        if ( $errstr ) {
            push @errors => $errstr;
            next;
        }

        $ret{$name} = +[
            map +{ type => $rel_type, id => @$_ },
            @{ $sth->fetchall_arrayref() }
        ];
    }

    if ( @errors ) {
        $doc->raise_error({ message => $_ }) for @errors;
        return;
    }

    return \%ret;
}

sub _db_execute {
    my ( $self, $stmt ) = @_;

    my $sth = $self->dbh->prepare($stmt->to_sql);
    my $ret = $sth->execute($stmt->to_bind);

    return ( $sth, ( !$ret ? $DBI::errstr : () ) );
}

sub _stmt_columns {
    my $self = shift;
    my $args = shift;
    my ( $fields, $type ) = @{$args}{qw< fields type >};

    ref $fields eq 'HASH' and exists $fields->{$type}
        or return $self->tables->{$type}->COLUMNS;

    my @fields_minus_relationship_keys =
        grep { !exists $self->tables->{$type}->RELATIONS->{$_} }
        @{ $fields->{$type} };

    return +[ 'id', @fields_minus_relationship_keys ];
}

sub _stmt_filters {
    my ( $self, $type, $filter ) = @_;

    return +{
        map   { $_ => $filter->{$_} }
        grep  { exists $filter->{$_} }
        @{ $self->tables->{$type}->COLUMNS }
    };
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
