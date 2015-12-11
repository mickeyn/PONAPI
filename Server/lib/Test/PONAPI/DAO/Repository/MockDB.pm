# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package Test::PONAPI::DAO::Repository::MockDB;

use Moose;

use DBI;
use DBD::SQLite::Constants qw/:result_codes/;;
use SQL::Composer;
use Scalar::Util qw/looks_like_number/;

use Test::PONAPI::DAO::Repository::MockDB::Loader;

use Test::PONAPI::DAO::Repository::MockDB::Table::Articles;
use Test::PONAPI::DAO::Repository::MockDB::Table::People;
use Test::PONAPI::DAO::Repository::MockDB::Table::Comments;

use PONAPI::DAO::Constants;
use PONAPI::DAO::Exception;

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

sub has_one_to_many_relationship {
    my ( $self, $type, $rel_name ) = @_;
    if ( my $table = $self->tables->{$type} ) {
        my $relations = $table->RELATIONS;
        return if !exists $relations->{ $rel_name };
        return !$relations->{ $rel_name }->ONE_TO_ONE;
    }
    return;
}

sub type_has_fields {
    my ($self, $type, $fields) = @_;

    # Check for invalid 'fields'
    my $table_obj = $self->tables->{$type};
    my %columns   = map +($_=>1), @{ $table_obj->COLUMNS };

    return 1 unless grep !exists $columns{$_}, @$fields;
    return;
}

sub retrieve_all {
    my ( $self, %args ) = @_;
    my $type = $args{type};

    $self->_validate_page($args{page}) if $args{page};

    my $stmt = $self->tables->{$type}->select_stmt(%args);
    $self->_add_resources( stmt => $stmt, %args );
}

sub retrieve {
    my ( $self, %args ) = @_;
    $args{filter}{id} = delete $args{id};
    $self->retrieve_all(%args);
}

sub retrieve_relationships {
    my ( $self, %args ) = @_;
    my ($type, $rel_type, $doc) = @args{qw/type rel_type document/};

    my $page = $args{page};
    $self->_validate_page($page) if $page;

    my $sort = $args{sort} || [];
    if ( @$sort ) {
        # TODO move to the request:
        PONAPI::DAO::Exception->throw(
            message => "You can only sort by id in retrieve_relationships"
        ) if @$sort > 1 || $sort->[0] !~ /\A(-)?id\z/;

        my $desc = !!$1;

        my $table_obj    = $self->tables->{$type};
        my $relation_obj = $table_obj->RELATIONS->{$rel_type};

        my $id_column     = $relation_obj->REL_ID_COLUMN;

        @$sort = ($desc ? '-' : '') . $id_column;
    }

    my $rels = $self->_find_resource_relationships(
        %args,
        # No need to fetch other relationship types
        fields => { $type => [ $rel_type ] },
    );

    return unless @{ $rels || [] };

    $doc->add_resource( %$_ ) for @$rels;

    $self->_add_pagination_links(
        page     => $page,
        document => $doc,
    ) if $page;

}

sub retrieve_by_relationship {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $rel_type, $fields, $include ) = @args{qw< document type rel_type fields include >};

    my $sort = delete $args{sort} || [];
    my $page = delete $args{page};
    $self->_validate_page($page) if $page;

    # We need to avoid passing sort and page here, since sort
    # will have columns for the actual data, not the relationship
    # table, and page needs to happen after sorting
    my $rels = $self->_find_resource_relationships(
        %args,
        # No need to fetch other relationship types
        fields => { $type => [ $rel_type ] },
    );

    return unless @$rels;

    my $q_type = $rels->[0]{type};
    my $q_ids  = [ map { $_->{id} } @{$rels} ];

    my $stmt = $self->tables->{$q_type}->select_stmt(
        type   => $q_type,
        fields => $fields,
        filter => { id => $q_ids },
        sort   => $sort,
        page   => $page,
    );

    $self->_add_resources(
        document => $doc,
        stmt     => $stmt,
        type     => $q_type,
        fields   => $fields,
        include  => $include,
        page     => $page,
        sort     => $sort,
    );
}

sub create {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $data ) = @args{qw< document type data >};

    my $dbh = $self->dbh;
    $dbh->begin_work;

    local $@;
    eval {
        $self->_create(%args);
        $dbh->commit;
    }
    or do {
        my $e = $@;
        $dbh->rollback;
        die $e;
    };
}

sub _create {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $data ) = @args{qw< document type data >};

    my $attributes    = $data->{attributes} || {};
    my $relationships = delete $data->{relationships} || {};

    my $table_obj = $self->tables->{$type};
    my ($stmt, $return, $extra) = $table_obj->insert_stmt(
        table  => $type,
        values => $attributes,
    );

    $self->_db_execute( $stmt );

    my $new_id = $self->dbh->last_insert_id("","","","");

    foreach my $rel_type ( keys %$relationships ) {
        my $rel_data = $relationships->{$rel_type};
        $rel_data = [ $rel_data ] if ref($rel_data) ne 'ARRAY';
        $self->_create_relationships(
            %args,
            id       => $new_id,
            rel_type => $rel_type,
            data     => $rel_data,
        );
    }

    # Spec says we MUST return this, both here and in the Location header;
    # the DAO takes care of the header, but we need to put it in the doc
    $doc->add_resource( type => $type, id => $new_id );

    $doc->set_status(201);
    return;
}

sub _create_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id, $rel_type, $data ) = @args{qw< type id rel_type data >};

    my $table_obj     = $self->tables->{$type};
    my $relation_obj = $table_obj->RELATIONS->{$rel_type};

    my $rel_table = $relation_obj->TABLE;
    my $key_type  = $relation_obj->TYPE;

    my $id_column     = $relation_obj->ID_COLUMN;
    my $rel_id_column = $relation_obj->REL_ID_COLUMN;

    my @all_values;
    foreach my $orig ( @$data ) {
        my $relationship = { %$orig };
        my $data_type = delete $relationship->{type};

        if ( $data_type ne $key_type ) {
            PONAPI::DAO::Exception->throw(
                message          => "Data has type `$data_type`, but we were expecting `$key_type`",
                bad_request_data => 1,
            );
        }

        $relationship->{$id_column}     = $id;
        $relationship->{$rel_id_column} = delete $relationship->{id};

        push @all_values, $relationship;
    }

    my $one_to_one = !$self->has_one_to_many_relationship($type, $rel_type);

    foreach my $values ( @all_values ) {
        my ($stmt, $return, $extra) = $relation_obj->insert_stmt(
            table  => $rel_table,
            values => $values,
        );

        eval  { $self->_db_execute( $stmt ); 1; }
        or do {
            my $e = $@;
            local $@ = $@;
            if ( $one_to_one && eval { $e->sql_error } ) {
                # Can't quite do ::Upsert
                $stmt = SQL::Composer::Update->new(
                    table  => $rel_table,
                    values => [ %$values ],
                    where  => [ $id_column => $id ],
                    driver => 'sqlite',
                );
                $self->_db_execute( $stmt );
            }
            else {
                die $e;
            }
        };
    }

    return PONAPI_UPDATED_NORMAL;
}

sub create_relationships {
    my ($self, %args) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my $ret;
    eval  { $ret = $self->_create_relationships( %args ); 1; }
    or do {
        my $e = $@||'Unknown error';
        $dbh->rollback;
        die $e;
    };

    $dbh->commit;
    return $ret;
    # TODO: add missing login
}

sub update {
    my ( $self, %args ) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my $ret;
    eval  { $ret = $self->_update( %args ); 1 }
    or do {
        my $e = $@;
        $dbh->rollback;
        die $e;
    };

    $dbh->commit;
    return $ret;
}

sub _update {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $data ) = @args{qw< document type id data >};

    # TODO this needs to be part of $data's validation in Request.pm
    my ($attributes, $relationships) = map $_||{}, @{ $data }{qw/ attributes relationships /};

    my $return = PONAPI_UPDATED_NORMAL;
    if ( %$attributes ) {
        my $table_obj = $self->tables->{$type};
        # Per the spec, the api behaves *very* differently if ->update does extra things
        # under the hood.  Case point: the updated column in Articles
        my ($stmt, $extra_return, $msg) = $table_obj->update_stmt(
            table  => $type,
            id     => $id,
            values => $attributes,
        );

        $return = $extra_return if defined $extra_return;

        my $sth = $self->_db_execute( $stmt );

        # We had a successful update, but it updated nothing
        if ( !$sth->rows ) {
            return PONAPI_UPDATED_NOTHING;
        }
    }

    if ( %$relationships ) {
        foreach my $rel_type ( keys %$relationships ) {
            $self->_update_relationships(
                document => $doc,
                type     => $type,
                id       => $id,
                rel_type => $rel_type,
                data     => $relationships->{$rel_type},
            );
        }
    }

    return $return;
}

sub _update_relationships {
    my ($self, %args) = @_;
    my ( $type, $id, $rel_type, $data ) = @args{qw< type id rel_type data >};

    if ( $data ) {
        $data = [ keys(%$data) ? $data : () ] if ref($data) eq 'HASH';

        $self->_clear_relationships(%args);
        if ( @$data ) {
            my $table_obj = $self->tables->{$type};
            my $relation_obj = $table_obj->RELATIONS->{$rel_type};

            my $rel_table       = $relation_obj->TABLE;
            my $column_rel_type = $relation_obj->TYPE;

            my $id_column     = $relation_obj->ID_COLUMN;
            my $rel_id_column = $relation_obj->REL_ID_COLUMN;

            foreach my $insert ( @$data ) {
                my %insert = %$insert;
                my $rel_id = delete $insert{id};

                delete $insert{type};

                $insert{$id_column}     = $id;
                $insert{$rel_id_column} = $rel_id;

                my ($stmt, $return, $extra) = $table_obj->insert_stmt(
                    table  => $rel_table,
                    values => \%insert,
                );

                $self->_db_execute( $stmt );
            }
        }
        return PONAPI_UPDATED_NORMAL;
    }
    else {
        return $self->_clear_relationships(%args);
    }
}

sub update_relationships {
    my ( $self, %args ) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my $ret;
    eval  { $ret = $self->_update_relationships( %args ); 1 }
    or do {
        my $e = $@;
        $dbh->rollback;
        die $e;
    };

    $dbh->commit;

    return $ret;
    # TODO: add missing login
}

sub _clear_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id, $rel_type ) = @args{qw< type id rel_type >};

    my $table_obj    = $self->tables->{$type};
    my $relation_obj = $table_obj->RELATIONS->{$rel_type};

    my $table     = $relation_obj->TABLE;
    my $id_column = $relation_obj->ID_COLUMN;

    my $stmt = $relation_obj->delete_stmt(
        table => $table,
        where => { $id_column => $id },
    );

    $self->_db_execute( $stmt );

    return PONAPI_UPDATED_NORMAL;
}

sub delete : method {
    my ( $self, %args ) = @_;
    my ( $type, $id ) = @args{qw< type id >};

    my $table_obj = $self->tables->{$type};
    my $stmt      = $table_obj->delete_stmt(
        table => $type,
        where => { id => $id },
    );

    my $sth = $self->_db_execute( $stmt );

    # TODO: Should this also clear relationships?

    return;
}

sub delete_relationships {
    my ( $self, %args ) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my $ret;
    eval {
        $ret = $self->_delete_relationships(%args);
        1;
    }
    or do {
        my $e = $@;
        $dbh->rollback;
        die $e;
    };

    $dbh->commit;

    return $ret;
}

sub _delete_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id, $rel_type, $data ) = @args{qw< type id rel_type data >};

    my $table_obj    = $self->tables->{$type};
    my $relation_obj = $table_obj->RELATIONS->{$rel_type};

    my $table    = $relation_obj->TABLE;
    my $key_type = $relation_obj->TYPE;

    my $id_column     = $relation_obj->ID_COLUMN;
    my $rel_id_column = $relation_obj->REL_ID_COLUMN;

    my @all_values;
    foreach my $resource ( @$data ) {
        my $data_type = delete $resource->{type};

        if ( $data_type ne $key_type ) {
            PONAPI::DAO::Exception->throw(
                message          => "Data has type `$data_type`, but we were expecting `$key_type`",
                bad_request_data => 1,
            );
        }

        my $delete_where = {
            $id_column     => $id,
            $rel_id_column => $resource->{id},
        };

        push @all_values, $delete_where;
    }

    my $ret = PONAPI_UPDATED_NORMAL;

    my $rows_modified = 0;
    DELETE:
    foreach my $where ( @all_values ) {
        my $stmt = $relation_obj->delete_stmt(
            table => $table,
            where => $where,
        );

        my $sth = $self->_db_execute( $stmt );
        $rows_modified += $sth->rows;
    }

    $ret = PONAPI_UPDATED_NOTHING if !$rows_modified;

    # TODO: add missing login
    return $ret;
}


## --------------------------------------------------------

sub _add_resources {
    my ( $self, %args ) = @_;
    my ( $doc, $stmt, $type ) =
        @args{qw< document stmt type >};

    my $sth = $self->_db_execute( $stmt );

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $id = delete $row->{id};
        my $rec = $doc->add_resource( type => $type, id => $id );
        $rec->add_attribute( $_ => $row->{$_} ) for keys %{$row};
        $rec->add_self_link;

        $self->_add_resource_relationships($rec, %args);
    }

    $self->_add_pagination_links(
        page => $args{page},
        rows => scalar $sth->rows,
        document => $doc,
    ) if $args{page};

    return;
}

sub _add_pagination_links {
    my ($self, %args) = @_;
    my ($page, $rows_fetched, $document) = @args{qw/page rows document/};
    $rows_fetched ||= -1;

    my ($offset, $limit) = @{$page}{qw/offset limit/};

    my %current = %$page;
    my %first = ( %current, offset => 0, );
    my (%previous, %next);

    if ( ($offset - $limit) >= 0 ) {
        %previous = %current;
        $previous{offset} -= $current{limit};
    }

    if ( $rows_fetched >= $limit ) {
        %next = %current;
        $next{offset} += $limit;
    }

    $document->add_pagination_links(
        first => \%first,
        self  => \%current,
        prev  => \%previous,
        next  => \%next,
    );
}

sub _validate_page {
    my ($self, $page) = @_;

    exists $page->{limit}
        or PONAPI::DAO::Exception->throw(message => "Limit missing for `page`");

    looks_like_number($page->{limit})
        or PONAPI::DAO::Exception->throw(message => "Bad limit value ($page->{limit}) in `page`");

    !exists $page->{offset} || looks_like_number($page->{offset})
        or PONAPI::DAO::Exception->throw(message => "Bad offset value in `page`");

    $page->{offset} ||= 0;

    return;
}

sub _add_resource_relationships {
    my ( $self, $rec, %args ) = @_;
    my $doc    = $rec->find_root;
    my $type   = $rec->type;
    my $fields = $args{fields};
    my %include = map { $_ => 1 } @{ $args{include} };

    # Do not add sort or page here -- those were for the primary resource
    # *only*.
    # TODO any way to make them happen here? Fetching a resource with a million
    # relationships seems bad.
    my $rels = $self->_fetchall_relationships(
        type     => $type,
        id       => $rec->id,
        document => $doc,
        fields   => $fields,
    );
    $rels or return;

    for my $r ( keys %$rels ) {
        my $relationship = $rels->{$r};
        @$relationship or next;

        my $rel_type = $relationship->[0]{type};

        # skipping the relationship if the type has an empty `fields` set
        next if exists $fields->{$rel_type} and !@{ $fields->{$rel_type} };

        my $one_to_many = $self->has_one_to_many_relationship($type, $r);
        for ( @$relationship ) {
            $rec->add_relationship( $r, $_, $one_to_many )
                ->add_self_link
                ->add_related_link;
        }

        $self->_add_included(
            $rel_type,                            # included type
            +[ map { $_->{id} } @$relationship ], # included ids
            %args                                 # filters / fields / etc.
        ) if exists $include{$r};
    }

    return;
}

sub _add_included {
    my ( $self, $type, $ids, %args ) = @_;
    my ( $doc, $filter, $fields ) = @args{qw< document filter fields >};

    $filter->{id} = $ids;

    # Do NOT add sort -- sort here was for the *main* resource!
    # TODO spec is vague regarding page here.  How do you paginate included
    # resources?
    my $stmt = $self->tables->{$type}->select_stmt(
        type   => $type,
        filter => $filter,
        fields => $fields,
    );

    my $sth = $self->_db_execute( $stmt );

    while ( my $inc = $sth->fetchrow_hashref() ) {
        my $id = delete $inc->{id};
        $doc->add_included( type => $type, id => $id )
            ->add_attributes( %{$inc} )
            ->add_self_link;
    }
}

sub _find_resource_relationships {
    my ( $self, %args ) = @_;
    my $rel_type = $args{rel_type};

    if ( $rel_type and my $rels = $self->_fetchall_relationships(%args) ) {
        return $rels->{$rel_type} if exists $rels->{$rel_type};
    }

    return [];
}

sub _fetchall_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id ) = @args{qw< type id >};

    # we don't want to autovivify $args{fields}{$type}
    # since it will be checked in order to know whether
    # the key existed in the original fields argument
    my %type_fields = exists $args{fields}{$type}
        ? map { $_ => 1 } @{ $args{fields}{$type} }
        : ();

    my %ret;
    my @errors;

    for my $name ( keys %{ $self->tables->{$type}->RELATIONS } ) {
        # If we have fields, and this relationship is not mentioned, skip
        # it.
        next if keys %type_fields > 0 and !exists $type_fields{$name};

        my $table_obj     = $self->tables->{$type};
        my $rel_table_obj = $table_obj->RELATIONS->{$name};
        my $rel_type      = $rel_table_obj->TYPE;
        my $rel_table     = $rel_table_obj->TABLE;
        my $id_column     = $rel_table_obj->ID_COLUMN;
        my $rel_id_column = $rel_table_obj->REL_ID_COLUMN;

        my $stmt = $rel_table_obj->select_stmt(
            %args,
            type   => $rel_table,
            filter => { $id_column => $id },
            fields => [ $rel_id_column ],
        );

        my $sth = $self->_db_execute( $stmt );

        $ret{$name} = +[
            map +{ type => $rel_type, id => $_->{$rel_id_column} },
            @{ $sth->fetchall_arrayref({}) }
        ];
    }

    return \%ret;
}

sub _db_execute {
    my ( $self, $stmt ) = @_;

    my ($sth, $ret);
    local $@;
    eval {
        $sth = $self->dbh->prepare($stmt->to_sql);
        $ret = $sth->execute($stmt->to_bind);
        # This should never happen, since the DB handle is
        # created with RaiseError.
        die $DBI::errstr if !$ret;
        1;
    } or do {
        my $e = "$@"||'Unknown error';
        my $errstr = $DBI::errstr;
        my $err_id = $DBI::err;

        my $message;
        if ( $err_id && $err_id == SQLITE_CONSTRAINT ) {
            PONAPI::DAO::Exception->throw(
                message   => "Table constraint failed: $errstr",
                sql_error => 1,
                status    => 409,
            );
        }
        # TODO better error messages for other codes
        elsif ( $err_id ) {
            PONAPI::DAO::Exception->throw(
                message   => $errstr,
                sql_error => 1,
            );
        }
        else {
            PONAPI::DAO::Exception->throw(
                message => "Non-SQL error while running query? $e"
            )
        }
    };

    return $sth;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
