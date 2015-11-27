package Test::PONAPI::DAO::Repository::MockDB;
use Moose;

use DBI;
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

    my $stmt = $self->tables->{$type}->select_stmt($type, %args);
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

    my $stmt = $self->tables->{$q_type}->select_stmt($q_type,
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
        convert_to_collection => 1,
    );
}

sub create {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $data ) = @args{qw< document type data >};

    my $attributes    = $data->{attributes} || {};
    my $relationships = delete $data->{relationships} || {};

    my $table_obj = $self->tables->{$type};
    my %columns   = map +($_=>1), @{ $table_obj->COLUMNS };
    if ( grep(exists $columns{$_}, keys %$attributes) != keys %$attributes ) {
        $doc->raise_error(400, { message => 'Unknown columns passed to create' });
        return PONAPI_UNKNOWN_RESOURCE_ERROR;
    }

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my $stmt = SQL::Composer::Insert->new(
        into   => $type,
        values => [ %$attributes ],
        driver => 'sqlite',
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    # TODO: 409 Conflict
    if ( $errstr ) {
        $dbh->rollback;
        $doc->raise_error(400, { message => $errstr });
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

        if ( $doc->has_errors ) {
            $dbh->rollback;
            return $ret;
        }
    }

    $dbh->commit;
    # Spec says we MUST return this, both here and in the Location header;
    # the DAO takes care of the header, but we need to put it in the doc
    $doc->add_resource( type => $type, id => $new_id );

    $doc->set_status(201);
    return 1;
}

sub _create_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    if ( ref($data) ne 'ARRAY' || !@$data ) {
        $doc->raise_error(400, {
            message => "create_relationships: Invalid data passed in",
        });
        return PONAPI_ERROR;
    }

    my $all_relations = $self->tables->{$type}->RELATIONS->{$rel_type};

    if ( !$all_relations ) {
        $doc->raise_error(400, { message => "create_relationship: unknown relationship $type -> $rel_type" });
        return PONAPI_UNKNOWN_RELATIONSHIP;
    }

    my @all_values;
    foreach my $orig ( @$data ) {
        my $relationship = { %$orig };
        my $data_type = delete $relationship->{type};
        my $key_type = $all_relations->{type};

        if ( $data_type ne $key_type ) {
            $doc->raise_error(400, {
                message => "creating a relationship of type $key_type, but data has type $data_type"
            });
            return PONAPI_CONFLICT_ERROR;
        }

        $relationship->{'id_' . $type}     = $id;
        $relationship->{'id_' . $key_type} = delete $relationship->{id};

        push @all_values, $relationship;
    }

    return PONAPI_ERROR if $doc->has_errors;

    my $table = $all_relations->{rel_table};
    my $one_to_one = !$self->has_one_to_many_relationship($type, $rel_type);

    if ( $one_to_one && @all_values > 1 ) {
        $doc->raise_error(400, {
            message => "Trying to update a one-on-one relationship multiple times",
        });
        return PONAPI_ERROR;
    }

    foreach my $values ( @all_values ) {
        my $stmt = SQL::Composer::Insert->new(
            into   => $table,
            values => [ %$values ],
            driver => 'sqlite',
        );

        my ( $sth, $errstr );
        eval  { ($sth, $errstr) = $self->_db_execute( $stmt ); 1 }
        or do { ($sth, $errstr) = ('', "$@"||"Unknown error");   };

        if ( $errstr ) {
            if ( $one_to_one ) {
                $stmt = SQL::Composer::Update->new(
                    table  => $table,
                    values => [ %$values ],
                    where  => [ 'id_' . $type => $id ],
                    driver => 'sqlite',
                );
                ($sth, $errstr) = $self->_db_execute( $stmt )
            }
        }
        
        if ( $errstr ) {
            $doc->raise_error(400, { message => $errstr });
            if ( $errstr =~ /column \S+ is not unique/ ) {
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
        $doc->raise_error(400, {message => $e});
    };

    if ( $doc->has_errors ) {
        $dbh->rollback;
    }
    else {
        $dbh->commit;
    }

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
        $doc->raise_error(400, {message => $e});
    };

    if ( $doc->has_errors ) {
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
        $doc->raise_error(400, { message => "update: unknown relationship $type -> $rel_type" });
        return PONAPI_UNKNOWN_RELATIONSHIP;
    }
    return PONAPI_ERROR if $doc->has_errors;

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
        if ( $PONAPI_ERROR_RETURN{$return} || !$stmt ) {
            $doc->raise_error(400, { message => $msg || 'Unknown error' });
            return $return;
        }

        my ( $sth, $errstr ) = $self->_db_execute( $stmt );
        if ( $errstr ) {
            $doc->raise_error(400, { message => $errstr });
            return PONAPI_ERROR;
        }

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
            if ( $doc->has_errors ) {
                return PONAPI_ERROR;
            }
        }
    }

    return $doc->has_errors ? PONAPI_ERROR : $return;
}

sub _update_relationships {
    my ($self, %args) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    if ( $data ) {
        $data = [ keys(%$data) ? $data : () ] if ref($data) eq 'HASH';

        my $clear_ret = $self->_clear_relationships(%args);
        return $clear_ret if $doc->has_errors;
        if ( @$data ) {
            my ( $column_rel_type, $rel_table ) = 
                    @{ $self->tables->{$type}->RELATIONS->{$rel_type} }{qw< type rel_table >}; 

            foreach my $insert ( @$data ) {
                my %insert = (%$insert, 'id_' . $type => $id);

                delete $insert{type};
                $insert{'id_' . $column_rel_type} = delete $insert{id};

                my $stmt = SQL::Composer::Insert->new(
                    into   => $rel_table,
                    values => [ %insert ],
                    driver => 'sqlite',
                );

                my ( $sth, $errstr ) = $self->_db_execute( $stmt );
                if ( $errstr ) {
                    $doc->raise_error(400, { message => $errstr });
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
        $doc->raise_error(400, {message => $e});
    };

    if ( $doc->has_errors ) {
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

    my $table = $self->tables->{$type}->RELATIONS->{$rel_type}{rel_table};

    my $stmt = SQL::Composer::Delete->new(
        from => $table,
        where => [ 'id_' . $type => $id ],
        driver => 'sqlite',
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    if ( $errstr ) {
        $doc->raise_error(400, { message => $errstr });
        return PONAPI_ERROR;
    }

    return PONAPI_UPDATED_NORMAL;
}

sub delete : method {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id ) = @args{qw< document type id >};

    my $stmt = SQL::Composer::Delete->new(
        from  => $type,
        where => [ id => $id ],
        driver => 'sqlite',
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error(400, { message => $errstr });

    # TODO: Should this also clear relationships?

    return 1;
}

sub delete_relationships {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $id, $rel_type, $data ) = @args{qw< document type id rel_type data >};

    my $relation_info = $self->tables->{$type}->RELATIONS->{$rel_type};

    my $table    = $relation_info->{rel_table};
    my $key_type = $relation_info->{type};

    my @all_values;
    foreach my $resource ( @$data ) {
        my $data_type = delete $resource->{type};

        if ( $data_type ne $key_type ) {
            $doc->raise_error(400, {
                message => "deleting a relationship of type $key_type, but data has type $data_type"
            });
            return PONAPI_CONFLICT_ERROR;
        }

        my $delete_where = {
            'id_' . $type     => $id,
            'id_' . $key_type => $resource->{id},
        };

        push @all_values, $delete_where;
    }

    my $rows_modified = 0;
    my $dbh = $self->dbh;
    $dbh->begin_work;
    DELETE:
    foreach my $where ( @all_values ) {
        my $stmt = SQL::Composer::Delete->new(
            from => $table,
            where => [ %$where ],
            driver => 'sqlite',
        );

        my ( $sth, $errstr ) = $self->_db_execute( $stmt );
        
        if ( $errstr ) {
            $doc->raise_error(400, { message => $errstr });
            last DELETE;
        }
        else {
            $rows_modified += $sth->rows;
        }
    }

    if ( $doc->has_errors ) {
        $dbh->rollback;
    }
    else {
        $dbh->commit;
    }
    
    if ( !$rows_modified ) {
        return PONAPI_UPDATED_NOTHING;
    }
    
    # TODO: add missing login
    return PONAPI_UPDATED_NORMAL;
}


## --------------------------------------------------------

sub _add_resources {
    my ( $self, %args ) = @_;
    my ( $doc, $stmt, $type, $convert_to_collection, $req_base ) =
        @args{qw< document stmt type convert_to_collection req_base >};

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error(400, { message => $errstr });

    my $counter = 0;

    while ( my $row = $sth->fetchrow_hashref() ) {
        if ( $counter == 1 && $convert_to_collection ) {
            $doc->convert_to_collection;
        }
        my $id = delete $row->{id};
        my $rec = $doc->add_resource( type => $type, id => $id );
        $rec->add_attribute( $_ => $row->{$_} ) for keys %{$row};
        $rec->add_self_link( $req_base );

        $self->_add_resource_relationships($rec, %args);
        $doc->has_errors and return;

        $counter++;
    }

    $doc->has_resources or $doc->add_null_resource;
}

sub _add_resource_relationships {
    my ( $self, $rec, %args ) = @_;
    my $doc  = $rec->find_root;
    my $type = $rec->type;
    my %include = map { $_ => 1 } @{ $args{include} };

    # check for invalid 'include' params
    my @invalid_includes = grep { !$self->has_relationship($type, $_) } keys %include;
    if ( @invalid_includes ) {
        $doc->raise_error(400, { message => "can't include type $_ (no relationship with $type)" })
            for @invalid_includes;
        return;
    }

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
}

sub _add_included {
    my ( $self, $type, $ids, %args ) = @_;
    my ( $doc, $filter, $fields ) = @args{qw< document filter fields >};

    $filter->{id} = $ids;

    my $stmt = $self->tables->{$type}->select_stmt($type,
        type   => $type,
        filter => $filter,
        fields => $fields,
    );

    my ( $sth, $errstr ) = $self->_db_execute( $stmt );
    $errstr and return $doc->raise_error(400, { message => $errstr });

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
            driver => 'sqlite',
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
        $doc->raise_error(400, { message => $_ }) for @errors;
        return;
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
        return undef, $e;
    };

    return ( $sth, ( !$ret ? $DBI::errstr : () ) );
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__
