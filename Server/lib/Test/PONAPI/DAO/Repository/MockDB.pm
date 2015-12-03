package Test::PONAPI::DAO::Repository::MockDB;
use Moose;

use DBI;
use DBD::SQLite::Constants qw/:result_codes/;;
use SQL::Composer;

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
        return !$relations->{ $rel_name }{one_to_one};
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
    my $doc  = $args{document};

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
    my $doc = $args{document};

    my $rels = $self->_find_resource_relationships(%args);

    if ( !@$rels ) {
        $doc->add_null_resource;
    }
    else {
        $doc->convert_to_collection
            if $self->has_one_to_many_relationship(@args{qw/type rel_type/});

        $doc->add_resource( %$_ ) for @{$rels};
    }
}

sub retrieve_by_relationship {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $rel_type, $fields, $include ) = @args{qw< document type rel_type fields include >};

    my $rels = $self->_find_resource_relationships(%args);

    if ( !@$rels ) {
        $doc->add_null_resource;
        return;
    }

    my $q_type = $rels->[0]{type};
    my $q_ids  = [ map { $_->{id} } @{$rels} ];

    my $stmt = $self->tables->{$q_type}->select_stmt(
        type   => $q_type,
        fields => $fields,
        filter => { id => $q_ids },
    );

    $self->_add_resources(
        document              => $doc,
        stmt                  => $stmt,
        type                  => $q_type,
        fields                => $fields,
        include               => $include,
        convert_to_collection => $self->has_one_to_many_relationship($type, $rel_type),
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
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    my $table_obj     = $self->tables->{$type};
    my $all_relations = $table_obj->RELATIONS->{$rel_type};

    my @all_values;
    foreach my $orig ( @$data ) {
        my $relationship = { %$orig };
        my $data_type = delete $relationship->{type};
        my $key_type = $all_relations->{type};

        if ( $data_type ne $key_type ) {
            PONAPI::DAO::Exception->throw(
                message          => "Data has type `$data_type`, but we were expecting `$key_type`",
                bad_request_data => 1,
            );
        }

        $relationship->{'id_' . $type}     = $id;
        $relationship->{'id_' . $key_type} = delete $relationship->{id};

        push @all_values, $relationship;
    }

    my $table = $all_relations->{rel_table};
    my $one_to_one = !$self->has_one_to_many_relationship($type, $rel_type);

    foreach my $values ( @all_values ) {
        my ($stmt, $return, $extra) = $table_obj->insert_stmt(
            table  => $table,
            values => $values,
        );

        eval  { $self->_db_execute( $stmt ); 1; }
        or do { 
            my $e = $@;
            local $@ = $@;
            if ( $one_to_one && eval { $e->sql_error } ) {
                # Can't quite do ::Upsert
                $stmt = SQL::Composer::Update->new(
                    table  => $table,
                    values => [ %$values ],
                    where  => [ 'id_' . $type => $id ],
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
    my $doc = $args{document};

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
    my $doc = $args{document};

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
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    if ( $data ) {
        $data = [ keys(%$data) ? $data : () ] if ref($data) eq 'HASH';

        $self->_clear_relationships(%args);
        if ( @$data ) {
            my $table_obj = $self->tables->{$type};
            my ( $column_rel_type, $rel_table ) =
                    @{ $table_obj->RELATIONS->{$rel_type} }{qw< type rel_table >};

            foreach my $insert ( @$data ) {
                my %insert = (%$insert, 'id_' . $type => $id);

                delete $insert{type};
                $insert{'id_' . $column_rel_type} = delete $insert{id};

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
    my $doc = $args{document};

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
    my ( $doc, $type, $id, $rel_type ) = @args{qw< document type id rel_type >};

    my $table_obj = $self->tables->{$type};
    my $table     = $table_obj->RELATIONS->{$rel_type}{rel_table};

    my $stmt = $table_obj->delete_stmt(
        table => $table,
        where => { 'id_' . $type => $id },
    );

    $self->_db_execute( $stmt );

    return PONAPI_UPDATED_NORMAL;
}

sub delete : method {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id ) = @args{qw< document type id >};

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
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    my $table_obj     = $self->tables->{$type};
    my $relation_info = $table_obj->RELATIONS->{$rel_type};

    my $table    = $relation_info->{rel_table};
    my $key_type = $relation_info->{type};

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
            'id_' . $type     => $id,
            'id_' . $key_type => $resource->{id},
        };

        push @all_values, $delete_where;
    }

    my $ret = PONAPI_UPDATED_NORMAL;

    my $rows_modified = 0;
    DELETE:
    foreach my $where ( @all_values ) {
        my $stmt = $table_obj->delete_stmt(
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
    my ( $doc, $stmt, $type, $convert_to_collection, $req_base ) =
        @args{qw< document stmt type convert_to_collection req_base >};

    my $sth = $self->_db_execute( $stmt );

    if ( $convert_to_collection ) {
        $doc->convert_to_collection;
    }

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $id = delete $row->{id};
        my $rec = $doc->add_resource( type => $type, id => $id );
        $rec->add_attribute( $_ => $row->{$_} ) for keys %{$row};
        $rec->add_self_link( $req_base );

        $self->_add_resource_relationships($rec, %args);
    }

    $doc->has_resources or $doc->add_null_resource;

    return;
}

sub _add_resource_relationships {
    my ( $self, $rec, %args ) = @_;
    my $doc  = $rec->find_root;
    my $type = $rec->type;
    my %include = map { $_ => 1 } @{ $args{include} };

    my $rels = $self->_fetchall_relationships(
        type     => $type,
        id       => $rec->id,
        document => $doc,
        fields   => $args{fields},
    );
    $rels or return;

    for my $r ( keys %$rels ) {
        my $relationship = $rels->{$r};
        @$relationship or next;

        my $one_to_many = $self->has_one_to_many_relationship($type, $r);
        for ( @$relationship ) {
            $rec->add_relationship( $r, $_, $one_to_many )
                ->add_self_link( $args{req_base} )
                ->add_related_link( $args{req_base} );
        }

        $self->_add_included(
            $relationship->[0]{type},             # included type
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
            ->add_self_link( $args{req_base} );
    }
}

sub _find_resource_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $rel_type ) = @args{qw< document rel_type >};

    my $rels = $self->_fetchall_relationships(%args);

    return $rels->{$rel_type} if exists $rels->{$rel_type};

    return [];
}

sub _fetchall_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id, $doc ) = @args{qw< type id doc >};
    my %type_fields = map { $_ => 1 } @{ $args{fields}{$type} };
    my %ret;
    my @errors;

    for my $name ( keys %{ $self->tables->{$type}->RELATIONS } ) {
        next if keys %type_fields > 0 and !exists $type_fields{$name};

        my $table_obj = $self->tables->{$type};
        my ( $rel_type, $rel_table ) =
            @{ $table_obj->RELATIONS->{$name} }{qw< type rel_table >};

        my $stmt = $table_obj->select_stmt(
            type   => $rel_table,
            filter => { 'id_' . $type => $id },
            fields => [ 'id_' . $rel_type ],
        );

        my $sth = $self->_db_execute( $stmt );

        $ret{$name} = +[
            map +{ type => $rel_type, id => @$_ },
            @{ $sth->fetchall_arrayref() }
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
