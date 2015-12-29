package PONAPI::DAO::Repository::Class::DBI;
use Moose::Role;
with 'PONAPI::DAO::Repository';

use PONAPI::DAO::Constants;
use PONAPI::DAO::Exception;

requires qw/tables _validate_page _next_page_info/;

sub has_type {
    my ($self, $type) = @_;
    return !!exists $self->tables->{$type};
}

my %relationships_cache;
sub _type_relationships {
    my ($self, $type) = @_;

    return @{ $relationships_cache{$type} } if $relationships_cache{$type}
                                            && !$self->{_skip_cache};

    my $meta = $self->tables->{$type}->__meta_info;
    my @rels;
    foreach my $value ( values %$meta ) {
        while ( my ($rel_name, $rel_info) = each %$value ) {
            push @rels, $rel_name if $rel_info->isa('Class::DBI::Relationship');
        }
    }

    return @{ $relationships_cache{$type} = \@rels };
}
sub has_relationship {
    my ($self, $type, $rel_type) = @_;
    my %relationships = map +($_=>1), $self->_type_relationships($type);
    return !!exists $relationships{$rel_type};
}

sub has_one_to_many_relationship {
    my ($self, $type, $rel_type) = @_;
    my $all_meta = $self->tables->{$type}->__meta_info;
    my $has_many = $all_meta->{has_many}{$rel_type};
    return if !$has_many || $has_many->{args}{one_to_one};
    return 1;
}

sub type_has_fields {
    my ($self, $type, $fields) = @_;

    my $table   = $self->tables->{$type};
    my $meta    = $table->__meta_info;
    my %columns = map +($_=>1), $table->columns,
                                $self->_type_relationships($type);

    foreach my $field ( @$fields ) {
        return unless exists $columns{$field};
    }

    return 1;
}


sub retrieve_all {
    my ($self, %args) = @_;
    my $type = $args{type};

    my $table   = $self->tables->{$type};
    my @columns = $table->columns;
    my %columns = map +($_=>1), @columns;

    my $page = $self->_validate_page($args{page});
    my $sort = $self->_validate_sort(\%columns, $args{sort});
    @$sort = map join(" ", @$_), @$sort if @$sort;

    my $where = ($args{filter}||{})->{$type} || { 1 => { '==', \1 } };

    my $primary = $table->primary_column;

    my %fields           = map +($_=>1), @{($args{fields}||{})->{$type} || []};
    my @retrieve_columns = %fields
                         ? ($primary, grep $fields{$_}, @columns)
                         : @columns;

    my $rows = $table->search_where(
        $where,
        {
            %$page,
            (@$sort ? (order_by => $sort) : ()),
            columns => \@retrieve_columns,
        }
    );

    my $doc          = $args{document};
    my $fetched_rows = 0;
    while ( my $row = $rows->next ) {
        my $id   = $row->{$primary};
        my %elem = map +($_ ne $primary ? ($_ => $row->{$_}) : ()), @retrieve_columns;

        my $rec = $doc->add_resource( type => $type, id => $id )
                      ->add_attributes( %elem )
                      ->add_self_link;

        # TODO only do this if we have include or fields with relationships
        $self->_add_resource_relationships($rec, %args, row => $row);

        $fetched_rows++;
    }

    $self->_add_pagination_links(
        page     => $page,
        rows     => $fetched_rows,
        document => $doc,
    ) if %$page;
}

sub _add_resource_relationships {
    my ($self, $rec, %args) = @_;

    my $type       = $args{type};
    my %fields     = map +($_=>1), @{($args{fields}||{})->{$type} || []};

    my $result_row = $args{row};
    my %include    = map +($_=>1), @{ $args{include} || [] };

    foreach my $rel_type ( $self->_type_relationships($type) ) {
        my $rows        = $result_row->$rel_type;
        next unless $rows;
        my $iterator = $rows->isa('Class::DBI::Iterator');

        my $one_to_many = $self->has_one_to_many_relationship($type => $rel_type);
        while ( my $rel = $iterator ? $rows->next : $rows ) {
            my $relationship_real_type = $rel->type;

            my %r = (
                id   => $rel->id,
                type => $relationship_real_type,
            );

            if ( !%fields || $fields{$rel_type} ) {
                $rec->add_relationship( $rel_type, \%r, $one_to_many )
                    ->add_self_link
                    ->add_related_link;
            }

            $self->_add_included(
                $rel_type,   # included type
                $rel,                 # included ids
                %args                 # filters / fields / etc.
            ) if exists $include{$rel_type};

            last if !$iterator;
        }
    }

    return;
}

# TODO catch duplicates here; we can avoid the get(@columns) that way
sub _add_included {
    my ($self, $rel_type, $rel_obj, %args) = @_;

    my $doc = $args{document};

    my $type    = $rel_obj->type;
    my $primary = $rel_obj->primary_column;
    my @columns = $rel_obj->columns;

    if ( $args{fields} ) {
        my %fields = map +($_=>1), @{($args{fields}||{})->{$type} || []};
        @columns = ($primary, grep $fields{$_}, @columns) if %fields;
    }

    $rel_obj->get( @columns );

    my %elem = map +($_ ne $primary ? ($_ => $rel_obj->{$_}) : ()), @columns;

    $doc->add_included( type => $type, id => $rel_obj->id )
        ->add_attributes( %elem )
        ->add_self_link;

}

sub retrieve {
    my ($self, %args) = @_;
    my $type = $args{type};

    my $table   = $self->tables->{$type};
    my $primary = $table->primary_column;

    $args{filter}{$type}{$primary} = { '==' => $args{id} };
    return $self->retrieve_all(%args);
}

sub _validate_sort {
    my ($self, $columns, $sort) = @_;

    my @sort;
    foreach my $sort_argument ( @{$sort||[]} ) {
        my ($desc, $column) = $sort_argument =~ /\A(-?)(.+)\z/s;
        next if !$columns->{$column};
        push @sort, [$column, $desc ? "DESC" : "ASC"];
    }

    return \@sort;
}

sub _add_pagination_links {
    my ($self, %args) = @_;
    my ($page, $rows_fetched, $document) = @args{qw/page rows document/};
    $rows_fetched ||= -1;

    my %next_page_info = $self->_next_page_info($page, $rows_fetched);

    $document->add_pagination_links( %next_page_info ) if %next_page_info;
}

sub retrieve_relationships {
    my ($self, %args) = @_;
    my ($type, $id, $rel_type) = @args{qw/type id rel_type/};

    my $retrieve_by_relationship = $args{retrieve_by_relationship};
    my $page = $self->_validate_page($args{page});

    my $table_class = $self->tables->{$type};

    if ( $table_class->meta_info(has_a => $rel_type) ) {
        ...; # TODO need to handle these
    }

    my $doc  = $args{document};
    my $meta = $table_class->__meta_info->{has_many};

    my $rel_info      = $meta->{$rel_type};
    my $foreign_class = $rel_info->foreign_class;
    my $foreign_key   = $rel_info->args->{foreign_key};

    # TODO explain...
    my $mapping       = $rel_info->args->{mapping};
    $mapping = $mapping ? $mapping->[0] : $rel_type;

    my $foreign_meta            = $foreign_class->__meta_info;
    my $relationship_real_table = $foreign_meta->{has_a}{$mapping}->foreign_class;

    if ( !$relationship_real_table ) {
        die "Huh, how can this happen?";
    }

    my $foreign_primary = $relationship_real_table->primary_column;

    my @real_columns = $relationship_real_table->columns;
    my %columns = map +($_=>1), @real_columns;
    my $sort = $self->_validate_sort(\%columns, $args{sort});

    my %extra_search_arguments = %$page;

    my @sort_clean;
    if ( $retrieve_by_relationship ) {
        @sort_clean = map "t2.@$_", @$sort;
        $extra_search_arguments{columns} = [
            $foreign_class->columns,
            map "t2.$_ t2_$_", @real_columns,
        ];
        $extra_search_arguments{source} = <<"EOJOIN";
            ${\ $foreign_class->table } t1
            JOIN ${\ $relationship_real_table->table } t2
            ON ( t1.$mapping = t2.$foreign_primary )
EOJOIN
    }
    else {
        die "retrieve_relationships only supports sorting by the primary key"
            if @$sort > 1 && !$retrieve_by_relationship;
        @sort_clean = $mapping . " " . $sort->[0][1]
            if @$sort;
    }

    $extra_search_arguments{order_by} = \@sort_clean if @sort_clean;

    my @rels = $foreign_class->search_where(
        { $foreign_key => { '==' => \$id } },
        \%extra_search_arguments,
    );

    my $relationship_real_type = $relationship_real_table->type;

    my @columns;
    if ( $retrieve_by_relationship ) {
        my %fields = map +($_=>1), @{($args{fields}||{})->{$type} || []};
        @columns = $relationship_real_table->columns;
        @columns = ($foreign_primary, grep $fields{$_}, @columns) if %fields;
    }

    foreach my $type_to_rel_type ( @rels ) {
        my $id      = $type_to_rel_type->{$mapping}{id};
        my $rec     = $doc->add_resource(
            type => $relationship_real_type,
            id   => $id,
        );

        next unless $retrieve_by_relationship;

        # No need for a ->get here; the join above ensured that we already
        # got the correct data
        my %elem = map +(exists($type_to_rel_type->{"t2_$_"}) ? ($_ => $type_to_rel_type->{"t2_$_"}) : ()), @columns;
        delete $elem{$foreign_primary};
        $rec->add_attributes( %elem )
            ->add_self_link;
    }

    $self->_add_pagination_links(
        page     => $page,
        document => $doc,
    ) if %$page;
}

sub retrieve_by_relationship {
    shift->retrieve_relationships(@_, retrieve_by_relationship => 1);
}

sub delete {
    my ( $self, %args ) = @_;
    my ( $type, $id ) = @args{qw< type id >};

    my $table_obj    = $self->tables->{$type};
    $table_obj->retrieve($id)->delete;

    return;
}

sub create {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $data ) = @args{qw< document type data >};

    my %insert        = %{ $data->{attributes}    || {} };
    my %relationships = %{ $data->{relationships} || {} };

    my $table_obj    = $self->tables->{$type};

    # If we have a has_many, insert it through create_relationships;
    # otherwise, do it through insert.
    # TODO test, also, might_have?
    if ( %relationships ) {
        foreach my $rel_type ( keys %relationships ) {
            next if $table_obj->meta_info(has_many => $rel_type);
            $insert{$rel_type} = (delete $relationships{$rel_type})->{id};
        }
    }

    my $new_resource = $table_obj->insert(\%insert);
    my $new_id       = $new_resource->id;

    foreach my $rel_type ( keys %relationships ) {
        $self->create_relationships(
            type     => $type,
            rel_type => $rel_type,
            id       => $new_id,
            data     => $relationships{$rel_type},
        );
    }

    # Spec says we MUST return this, both here and in the Location header;
    # the DAO takes care of the header, but we need to put it in the doc
    $doc->add_resource( type => $type, id => $new_id );

    return;
}
sub update {
    my ( $self, %args ) = @_;
    my ( $type, $id, $data ) = @args{qw< type id data >};

    my $attributes    = $data->{attributes}    || {};
    my $relationships = $data->{relationships} || {};

    my $return = PONAPI_UPDATED_NORMAL;
    if ( %$attributes ) {
        my $table_class = $self->tables->{$type};

        # Class::DBI wants to do a retrieve before updating. Let's not.
        my $horrible_hack = $table_class->new();
        $horrible_hack->{id} = $id;

        my $rows_updated = 0;
        $horrible_hack->add_trigger(after_update => sub {
            my ($self, %args) = @_;
            my $discard_columns = $args{discard_columns};

            $rows_updated += $DBI::rows;
        });

        $horrible_hack->set(%$attributes);
        my $return = $horrible_hack->update;

        # We had a successful update, but it updated nothing
        if ( ($return != 1) || !$rows_updated ) {
            $return = PONAPI_UPDATED_NOTHING;
        }
    }

    foreach my $rel_type ( keys %$relationships ) {
        my $update_rel_return = $self->update_relationships(
            type     => $type,
            id       => $id,
            rel_type => $rel_type,
            data     => $relationships->{$rel_type},
        );

        # We tried updating the attributes but
        $return = $update_rel_return
            if $return            == PONAPI_UPDATED_NOTHING
            && $update_rel_return != PONAPI_UPDATED_NOTHING;
    }

    return $return;
}

sub update_relationships {
    my ($self, %args) = @_;
    my ( $type, $id, $rel_type, $data ) = @args{qw< type id rel_type data >};
    my $table_obj    = $self->tables->{$type};

    my $meta         = $table_obj->meta_info(has_many => $rel_type);
    if ( !$meta ) {
        # has_a on the same table, we need a simple update...
        if ( ref($data||'') eq 'ARRAY' ) {
            PONAPI::DAO::Exception->throw(
                message          => "Data is a collection, but $type -> $rel_type is one-on-one",
                bad_request_data => 1,
            );
        }

        my $update_to = defined($data) ? $data->{id} : $data;
        return $self->update(
            %args,
            data => { attributes => { $rel_type => $update_to } }
        );
    }

    my $rel_table     = $meta->foreign_class;
    my $args          = $meta->args;
    my $foreign_key   = $args->{foreign_key};
    my $mapping       = $args->{mapping};
    $mapping = $mapping ? $mapping->[0] : $rel_type;

    # Let's start by clearing all relationships; this way
    # we can implement the SQL below without adding special cases
    # for ON DUPLICATE KEY UPDATE and sosuch.
    $rel_table->search({ $foreign_key => $id })->delete_all;

    # Let's have an arrayref
    $data = $data
            ? ref($data) eq 'HASH' ? [ keys(%$data) ? $data : () ] : $data
            : [];

    foreach my $insert ( @$data ) {
        $rel_table->insert({
            $foreign_key => $id,
            $mapping     => $insert->{id},
        });
    }

    return PONAPI_UPDATED_NORMAL;
}

sub create_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $data, $rel_type, $id ) = @args{qw< type data rel_type id>};

    my $table_obj      = $self->tables->{$type};
    my $meta           = $table_obj->meta_info(has_many => $rel_type);

    my $rel_table     = $meta->foreign_class;
    my $args          = $meta->args;
    my $foreign_key   = $args->{foreign_key};
    my $mapping       = $args->{mapping};
    $mapping = $mapping ? $mapping->[0] : $rel_type;

    $data = [ $data ] if ref($data) ne 'ARRAY';
    $rel_table->insert({
        $foreign_key => $id,
        $mapping     => $_->{id},
    }) for @$data;

    return PONAPI_UPDATED_NORMAL;
}

sub delete_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $data, $rel_type, $id ) = @args{qw< type data rel_type id>};

    my $table_obj      = $self->tables->{$type};
    my $meta           = $table_obj->meta_info(has_many => $rel_type);

    my $rel_table     = $meta->foreign_class;
    my $args          = $meta->args;
    my $foreign_key   = $args->{foreign_key};
    my $mapping       = $args->{mapping};
    $mapping = $mapping ? $mapping->[0] : $rel_type;

    $rel_table->search_where({
        $foreign_key => $id,
        $mapping     => [map $_->{id}, @$data],
    })->delete_all;

    return PONAPI_UPDATED_NORMAL;
}

no Moose::Role; 1;
__END__
