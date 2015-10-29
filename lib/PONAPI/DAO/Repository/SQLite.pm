package PONAPI::DAO::Repository::SQLite;
use Moose;

use DBI;
use SQL::Composer;

with 'PONAPI::DAO::Repository';

has driver => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'SQLite' },
);

has dbd => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'DBI:SQLite:dbname=MockDB.db' },
);

has dbh => (
    is      => 'ro',
    isa     => 'DBI::db',
    lazy    => 1,
    builder => '_build_dbh',
);

sub _build_dbh {
    my $self = shift;
    DBI->connect( $self->dbd, '', '', { RaiseError => 1 } )
        or die $DBI::errstr;
}

sub BUILD {
    my $self = shift;

    $self->dbh->do($_) for
        q< DROP TABLE IF EXISTS articles; >,
        q< CREATE TABLE IF NOT EXISTS articles (
             id            INTEGER     PRIMARY KEY AUTOINCREMENT,
             title         CHAR(64)    NOT NULL,
             body          TEXT        NOT NULL,
             created       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
             updated       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
             status        CHAR(10)    NOT NULL   DEFAULT "pending approval" ); >,

        q< INSERT INTO articles (title, body, created, updated, status) VALUES
             ("JSON API paints my bikeshed!", "The shortest article. Ever.",
              "2015-05-22 14:56:29", "2015-05-22 14:56:29", "ok" ),
             ("A second title", "The 2nd shortest article. Ever.",
              "2015-06-22 14:56:29", "2015-06-22 14:56:29", "ok" ),
             ("a third one", "The 3rd shortest article. Ever.",
              "2015-07-22 14:56:29", "2015-07-22 14:56:29", "pending approval" ); >,

        q< DROP TABLE IF EXISTS people; >,
        q< CREATE TABLE IF NOT EXISTS people (
             id            INTEGER     PRIMARY KEY,
             name          CHAR(64)    NOT NULL   DEFAULT "anonymous",
             age           INTEGER     NOT NULL   DEFAULT "100",
             gender        CHAR(10)    NOT NULL   DEFAULT "unknown" ); >,

        q< INSERT INTO people (id, name, age, gender) VALUES
             (42, "John",  80, "male"),
             (88, "Jimmy", 18, "male"),
             (91, "Diana", 30, "female") >,

        q< DROP TABLE IF EXISTS rel_articles_people; >,
        q< CREATE TABLE IF NOT EXISTS rel_articles_people (
             id_articles   INTEGER     UNIQUE     NOT NULL,
             id_people     INTEGER     UNIQUE     NOT NULL ); >,

        q< INSERT INTO rel_articles_people (id_articles, id_people) VALUES
             (1, 42),
             (2, 88),
             (3, 91) >,

        q< DROP TABLE IF EXISTS comments; >,
        q< CREATE TABLE IF NOT EXISTS comments (
             id            INTEGER     PRIMARY KEY,
             body          TEXT        NOT NULL DEFAULT "" ); >,

        q< INSERT INTO comments (id, body) VALUES
             (5,  "First!"),
             (12, "I like XML better") >,

        q< DROP TABLE IF EXISTS rel_articles_comments; >,
        q< CREATE TABLE IF NOT EXISTS rel_articles_comments (
             id_articles   INTEGER     NOT NULL,
             id_comments   INTEGER     UNIQUE     NOT NULL ); >,

        q< INSERT INTO rel_articles_comments (id_articles, id_comments) VALUES
             (2, 5),
             (2, 12) >;
}

my %TABLE_RELATIONS = (
    articles => {
        authors  => { type => 'people',   rel_table => 'rel_articles_people'   },
        comments => { type => 'comments', rel_table => 'rel_articles_comments' },
    },
    people   => {
        articles => { type => 'articles', rel_table => 'rel_articles_people'   },
    },
    comments => {
        articles => { type => 'articles', rel_table => 'rel_articles_comments' },
    },
);

my %TABLE_COLUMNS = (
    articles => [qw< id title body created updated status >],
    people   => [qw< id name age gender >],
    comments => [qw< id body >],
);

sub has_type {
    my ( $self, $type ) = @_;
    !! exists $TABLE_RELATIONS{$type};
}

sub has_relationship {
    my ( $self, $type, $rel_name ) = @_;
    !! exists $TABLE_RELATIONS{$type}{$rel_name};
}

sub retrieve_all {
    my ( $self, %args ) = @_;
    my $type = $args{type};

    my $filters = _stmt_filters($type, $args{filter});

    my $stmt = SQL::Composer::Select->new(
        from    => $type,
        columns => _stmt_columns(\%args),
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
    my $doc = $args{document};

    my $rels = $self->_find_resource_relationships(%args)
        or return;

    my $q_type = $rels->[0]{type};
    my $q_ids  = [ map { $_->{id} } @{$rels} ];

    my $stmt = SQL::Composer::Select->new(
        from    => $q_type,
        columns => _stmt_columns({ type => $q_type }),
        where   => [ id => $q_ids ],
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error({ message => $errstr });

    my @resources = @{ $sth->fetchall_arrayref() };
    @resources or return $doc->raise_error({
        message => "data inconsistency, relationship points to a missing resource"
    });
# shouldn't this method always assume collection request?
# -- mickey
    @resources > 1 and $doc->convert_to_collection;

    $doc->add_resource( type => $_->[1], id => $_->[0] ) for @resources;
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


## --------------------------------------------------------

sub _add_resources {
    my ( $self, %args ) = @_;
    my ( $doc, $stmt, $type ) = @args{qw< document stmt type >};

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error({ message => $errstr });

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $id = delete $row->{id};
        my $rec = $doc->add_resource( type => $type, id => $id );
        $rec->add_attribute( $_ => $row->{$_} ) for keys %{$row};

        $self->_add_resource_relationships($rec, %args);
    }

    $doc->has_resources or $doc->add_null_resource;
}

sub _add_resource_relationships {
    my ( $self, $rec, %args ) = @_;
    my $doc = $rec->find_root;
    my %include = map { $_ => 1 } @{ $args{include} };

    my $rels = $self->_fetchall_relationships( $rec->type, $rec->id, $doc )
        or return;

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
        columns => _stmt_columns({ type => $type, fields => $fields }),
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
    my ( $doc, $type, $id, $rel_type ) = @args{qw< document type id rel_type >};

    my $rels = $self->_fetchall_relationships( $type, $id, $doc )
        or return;

    return $rels->{$rel_type} if exists $rels->{$rel_type};

    $doc->add_null_resource();
    return;
}

sub _fetchall_relationships {
    my ( $self, $type, $id, $doc ) = @_;
    my %ret;
    my @errors;

    for my $name ( keys %{ $TABLE_RELATIONS{$type} } ) {
        my ( $rel_type, $rel_table ) =
            @{$TABLE_RELATIONS{$type}{$name}}{qw< type rel_table >};

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

    return ( $sth, ( $ret < 0 ? $DBI::errstr : () ) );
}

sub _stmt_columns {
    my $args = shift;
    my ( $fields, $type ) = @{$args}{qw< fields type >};

    ref $fields eq 'HASH' and exists $fields->{$type}
        or return $TABLE_COLUMNS{$type};

    return +[ 'id', @{ $fields->{$type} } ];
}

sub _stmt_filters {
    my ( $type, $filter ) = @_;

    return +{
        map   { $_ => $filter->{$_} }
        grep  { exists $filter->{$_} }
        @{ $TABLE_COLUMNS{$type} }
    };
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
