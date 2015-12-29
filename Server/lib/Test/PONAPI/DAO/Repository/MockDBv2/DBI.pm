package Test::PONAPI::DAO::Repository::MockDBv2::DBI;
use strict; use warnings;
use parent 'Class::DBI';

use File::Temp qw/tempfile/;
my $db_path;
sub _dbd {
    if (!$db_path) {
        my ($fh, $path) = tempfile("MockDB.db.XXXXXXX",
            TMPDIR => 1,
            UNLINK => 1,
        );
        close $fh;
        $db_path = "$path";
    }
    return "DBI:SQLite:dbname=$db_path";
}

sub set_table {
    my ($class, $table) = @_;
    $class->table($table);
    $class->_create_test_table;
}

sub _create_test_table {
    my $class = shift;
    $class->sql__create_me($class->create_sql)->execute;
}

__PACKAGE__->set_sql(_create_me    => 'CREATE TABLE __TABLE__ (%s)');
__PACKAGE__->connection( _dbd(), '', '', { RaiseError => 1 } );

# TODO these need to be in a role or parent class
sub type { $_[0]->table }

use SQL::Abstract::Limit;
sub search_where {
    my $class = shift;
    my $where = (ref $_[0]) ? $_[0] : { @_ };
    my $attr  = (ref $_[0]) ? $_[1] : {};
    my $order   = delete $attr->{order_by};
    my $limit   = delete $attr->{limit};
    my $offset  = delete $attr->{offset};
    my $columns = delete $attr->{columns} || [ $class->columns ];
    my $source  = delete $attr->{source}   || $class->table;

    my $sql = SQL::Abstract::Limit->new(%$attr, limit_dialect => $class->db_Main);
    my($phrase, @bind) = $sql->where($where, $order, $limit, $offset);
    $phrase =~ s/^\s*WHERE\s*//i;

    my $columns_sql = join ", ", @$columns;

    my $actual_sql = $class->sql__retrieve_with_columns($columns_sql, $source, $phrase);
    return
        $class->sth_to_objects($actual_sql, \@bind);
}

__PACKAGE__->set_sql(_retrieve_with_columns => <<'EOSQL');
    SELECT %s
    FROM %s
    WHERE %s
EOSQL

1;
__END__