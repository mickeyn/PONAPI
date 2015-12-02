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

sub retrieve_all {
    my ( $self, %args ) = @_;
    my $type = $args{type};
    my $doc  = $args{document};

    my $stmt = $self->tables->{$type}->select_stmt(%args);
    return $self->_add_resources( stmt => $stmt, %args );
}

sub retrieve {
    my ( $self, %args ) = @_;
    $args{filter}{id} = delete $args{id};
    return $self->retrieve_all(%args);
}

sub retrieve_relationships {
    my ( $self, %args ) = @_;
    my $doc = $args{document};

    my $rels = $self->_find_resource_relationships(%args);

    if ( !$rels || !ref $rels ) {
        $rels ||= PONAPI_ERROR;
        return $rels;
    }
    elsif ( !@$rels ) {
        $doc->add_null_resource;
    }
    else {
        $doc->convert_to_collection
            if $self->has_one_to_many_relationship(@args{qw/type rel_type/});

        $doc->add_resource( %$_ ) for @{$rels};
    }

    return PONAPI_OK;
}

sub retrieve_by_relationship {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $rel_type, $fields, $include ) = @args{qw< document type rel_type fields include >};

    my $rels = $self->_find_resource_relationships(%args);

    if ( !$rels || !ref($rels) ) {
        $rels ||= PONAPI_ERROR;
        return $rels;
    }
    elsif ( !@$rels ) {
        $doc->add_null_resource;
        return PONAPI_OK;
    }

    my $q_type = $rels->[0]{type};
    my $q_ids  = [ map { $_->{id} } @{$rels} ];

    my $stmt = $self->tables->{$q_type}->select_stmt(
        type   => $q_type,
        fields => $fields,
        filter => { id => $q_ids },
    );

    return $self->_add_resources(
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

    my $attributes    = $data->{attributes} || {};
    my $relationships = delete $data->{relationships} || {};

    my $table_obj = $self->tables->{$type};
    my %columns   = map +($_=>1), @{ $table_obj->COLUMNS };
    my @unknown   = grep !exists $columns{$_}, keys %$attributes;
    if ( @unknown ) {
        return PONAPI_UNKNOWN_RESOURCE_IN_DATA;
    }

    my ($stmt, $return, $extra) = $table_obj->insert_stmt(
        table  => $type,
        values => $attributes,
    );

    if ( $return && $PONAPI_ERROR_RETURN{$return} ) {
        return $return, $extra;
    }

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    # TODO: 409 Conflict
    if ( $errstr ) {
        $dbh->rollback;
        return PONAPI_ERROR;
    }

    my $new_id = $dbh->last_insert_id("","","","");

    foreach my $rel_type ( keys %$relationships ) {
        my $rel_data = $relationships->{$rel_type};
        $rel_data = [ $rel_data ] if ref($rel_data) ne 'ARRAY';
        my $ret = $self->_create_relationships(
            %args,
            id       => $new_id,
            rel_type => $rel_type,
            data     => $rel_data,
        );

        if ( $ret && $PONAPI_ERROR_RETURN{$ret} ) {
            $dbh->rollback;
            return $ret;
        }
    }

    $dbh->commit;
    # Spec says we MUST return this, both here and in the Location header;
    # the DAO takes care of the header, but we need to put it in the doc
    $doc->add_resource( type => $type, id => $new_id );

    $doc->set_status(201);
    return PONAPI_OK;
}

sub _create_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    if ( ref($data) ne 'ARRAY' || !@$data ) {
        return PONAPI_BAD_DATA;
    }

    my $table_obj     = $self->tables->{$type};
    my $all_relations = $table_obj->RELATIONS->{$rel_type};

    if ( !%{ $all_relations || {} } ) {
        return PONAPI_UNKNOWN_RELATIONSHIP;
    }

    my @all_values;
    foreach my $orig ( @$data ) {
        my $relationship = { %$orig };
        my $data_type = delete $relationship->{type};
        my $key_type = $all_relations->{type};

        if ( $data_type ne $key_type ) {
            return PONAPI_BAD_DATA;
        }

        $relationship->{'id_' . $type}     = $id;
        $relationship->{'id_' . $key_type} = delete $relationship->{id};

        push @all_values, $relationship;
    }

    my $table = $all_relations->{rel_table};
    my $one_to_one = !$self->has_one_to_many_relationship($type, $rel_type);

    if ( $one_to_one && @all_values > 1 ) {
        return PONAPI_BAD_DATA;
    }

    foreach my $values ( @all_values ) {
        my ($stmt, $return, $extra) = $table_obj->insert_stmt(
            table  => $table,
            values => $values,
        );

        if ( $return && $PONAPI_ERROR_RETURN{$return} ) {
            return $return, $extra;
        }

        my ( $sth, $errstr, $err_id );
        eval  { ($sth, $errstr, $err_id) = $self->_db_execute( $stmt ); 1; }
        or do { ($sth, $errstr, $err_id) = ('', "$@"||"Unknown error", $DBI::err) };

        if ( $errstr && $one_to_one ) {
            # Can't quite do ::Upsert
            $stmt = SQL::Composer::Update->new(
                table  => $table,
                values => [ %$values ],
                where  => [ 'id_' . $type => $id ],
                driver => 'sqlite',
            );
            ($sth, $errstr, $err_id) = $self->_db_execute( $stmt );
        }

        if ( $errstr ) {
            if ( ($err_id||-1) == SQLITE_CONSTRAINT ) {
                return PONAPI_CONFLICT_ERROR;
            }
            return PONAPI_ERROR;
        }
    }

    return PONAPI_UPDATED_NORMAL;
}

sub create_relationships {
    my ($self, %args) = @_;
    my $doc = $args{document};

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my $ret;
    eval  { $ret = $self->_create_relationships( %args ); 1 }
    or do {
        my $e = "$@"||'Unknown error';
        $ret = PONAPI_ERROR;
    };

    if ( $PONAPI_ERROR_RETURN{$ret} ) {
        $dbh->rollback;
        return $ret;
    }

    $dbh->commit;

    return $ret;

    # TODO: check type can have To-Many relationships or error

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
        my $e = "$@"||'Unknown error';
        $ret = PONAPI_ERROR;
    };

    if ( $PONAPI_ERROR_RETURN{$ret} ) {
        $dbh->rollback;
    }
    else {
        $dbh->commit;
    }

    return $ret;
}

sub _update {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $data ) = @args{qw< document type id data >};

    # TODO this needs to be part of $data's validation in Request.pm
    my ($attributes, $relationships) = map $_||{}, @{ $data }{qw/ attributes relationships /};

    foreach my $rel_type ( keys %$relationships ) {
        next if $self->has_relationship($type, $rel_type);
        return PONAPI_UNKNOWN_RELATIONSHIP;
    }

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
        if ( $PONAPI_ERROR_RETURN{$return} ) {
            return $return;
        }

        my ( $sth, $errstr ) = $self->_db_execute( $stmt );
        if ( $errstr ) {
            return PONAPI_ERROR;
        }

        # We had a successful update, but it updated nothing
        if ( !$sth->rows ) {
            return PONAPI_UPDATED_NOTHING;
        }
    }

    if ( %$relationships ) {
        foreach my $rel_type ( keys %$relationships ) {
            my $return = $self->_update_relationships(
                document => $doc,
                type     => $type,
                id       => $id,
                rel_type => $rel_type,
                data     => $relationships->{$rel_type},
            );
            if ( $return && $PONAPI_ERROR_RETURN{$return} ) {
                return $return;
            }
        }
    }

    return $return;
}

sub _update_relationships {
    my ($self, %args) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    if ( $data ) {
        $data = [ keys(%$data) ? $data : () ] if ref($data) eq 'HASH';

        my $clear_ret = $self->_clear_relationships(%args);
        return $clear_ret if $clear_ret && $PONAPI_ERROR_RETURN{$clear_ret};
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

                if ( $return && $PONAPI_ERROR_RETURN{$return} ) {
                    $extra->{detail} ||= 'Unknown error';
                    return $return, $extra;
                }

                my ( $sth, $errstr ) = $self->_db_execute( $stmt );
                if ( $errstr ) {
                    return PONAPI_ERROR;
                }
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
        my $e = "$@"||'Unknown error';
        $ret = PONAPI_ERROR;
    };

    if ( $PONAPI_ERROR_RETURN{$ret} ) {
        $dbh->rollback;
    }
    else {
        $dbh->commit;
    }

    return $ret;

    # TODO: check type can have To-Many relationships or error

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

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    if ( $errstr ) {
        return PONAPI_ERROR;
    }

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

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return PONAPI_ERROR;

    # TODO: Should this also clear relationships?

    return PONAPI_OK;
}

sub delete_relationships {
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
            return PONAPI_CONFLICT_ERROR;
        }

        my $delete_where = {
            'id_' . $type     => $id,
            'id_' . $key_type => $resource->{id},
        };

        push @all_values, $delete_where;
    }

    my $ret = PONAPI_UPDATED_NORMAL;

    my $rows_modified = 0;
    my $dbh = $self->dbh;
    $dbh->begin_work;
    DELETE:
    foreach my $where ( @all_values ) {
        my $stmt = $table_obj->delete_stmt(
            table => $table,
            where => $where,
        );

        my ( $sth, $errstr ) = $self->_db_execute( $stmt );

        if ( $errstr ) {
            $ret = PONAPI_ERROR;
            last DELETE;
        }
        else {
            $rows_modified += $sth->rows;
        }
    }

    if ( $PONAPI_ERROR_RETURN{$ret} ) {
        $dbh->rollback;
    }
    else {
        $ret = PONAPI_UPDATED_NOTHING if !$rows_modified;
        $dbh->commit;
    }


    # TODO: add missing login
    return $ret;
}


## --------------------------------------------------------

sub _add_resources {
    my ( $self, %args ) = @_;
    my ( $doc, $stmt, $type, $convert_to_collection, $req_base ) =
        @args{qw< document stmt type convert_to_collection req_base >};

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return PONAPI_ERROR;

    if ( $convert_to_collection ) {
        $doc->convert_to_collection;
    }

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $id = delete $row->{id};
        my $rec = $doc->add_resource( type => $type, id => $id );
        $rec->add_attribute( $_ => $row->{$_} ) for keys %{$row};
        $rec->add_self_link( $req_base );

        my $ret = $self->_add_resource_relationships($rec, %args);
        return $ret if $PONAPI_ERROR_RETURN{$ret};
    }

    $doc->has_resources or $doc->add_null_resource;

    return PONAPI_OK;
}

sub _add_resource_relationships {
    my ( $self, $rec, %args ) = @_;
    my $doc  = $rec->find_root;
    my $type = $rec->type;
    my %include = map { $_ => 1 } @{ $args{include} };

    # check for invalid 'include' params
    foreach my $rel_type ( keys %include ) {
        next if $self->has_relationship($type, $rel_type);
        return PONAPI_UNKNOWN_RELATIONSHIP, { type => $type, rel_type => $rel_type };
    }

    my $rels = $self->_fetchall_relationships(
        type     => $type,
        id       => $rec->id,
        document => $doc,
        fields   => $args{fields},
    );
    $rels or return PONAPI_OK;
    return $rels if $PONAPI_ERROR_RETURN{$rels};

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

    return PONAPI_OK;
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

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return PONAPI_ERROR;

    while ( my $inc = $sth->fetchrow_hashref() ) {
        my $id = delete $inc->{id};
        $doc->add_included( type => $type, id => $id )
            ->add_attributes( %{$inc} );
    }
}

sub _find_resource_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $rel_type ) = @args{qw< document rel_type >};

    my $rels = $self->_fetchall_relationships(%args) || PONAPI_ERROR;

    return $rels if $PONAPI_ERROR_RETURN{$rels};

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

        my ( $sth, $errstr ) = $self->_db_execute( $stmt );
        if ( $errstr ) {
            return PONAPI_ERROR;
        }

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
        1;
    } or do {
        my $e = "$@"||'Unknown error';
        return undef, $e, $DBI::err;
    };

    return ( $sth, ( !$ret ? ($DBI::errstr, $DBI::err) : () ) );
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
