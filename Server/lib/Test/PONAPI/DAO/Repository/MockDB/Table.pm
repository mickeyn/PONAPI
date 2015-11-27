package Test::PONAPI::DAO::Repository::MockDB::Table;
use Moose;
use SQL::Composer;

use PONAPI::DAO::Constants;

sub select_stmt {
    my ($self, $type, %args) = @_;

    my $filters = $self->_stmt_filters($type, $args{filter});
    my $stmt = SQL::Composer::Select->new(
        from    => $type,
        columns => $self->_stmt_columns(\%args),
        where   => [ %{ $filters } ],
    );

    return $stmt;
}

sub update_stmt {
    my ($self, $type, $id, $values) = @_;
    local $@;
    my $msg = '';
    my $stmt = eval { SQL::Composer::Update->new(
        table  => $type,
        values => [ %$values ],
        where  => [ id => $id ],
    ) } or do { $msg = "$@"||'Unknown error' };

    return $stmt, PONAPI_UPDATED_NORMAL, $msg;
}

sub _stmt_columns {
    my $self = shift;
    my $args = shift;
    my ( $fields, $type ) = @{$args}{qw< fields type >};

    ref $fields eq 'HASH' and exists $fields->{$type}
        or return $self->COLUMNS;

    my @fields_minus_relationship_keys =
        grep { !exists $self->RELATIONS->{$_} }
        @{ $fields->{$type} };

    return +[ 'id', @fields_minus_relationship_keys ];
}

sub _stmt_filters {
    my ( $self, $type, $filter ) = @_;

    return +{
        map   { $_ => $filter->{$_} }
        grep  { exists $filter->{$_} }
        @{ $self->COLUMNS }
    };
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;
__END__

