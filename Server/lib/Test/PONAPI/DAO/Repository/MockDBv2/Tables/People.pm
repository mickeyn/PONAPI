package Test::PONAPI::DAO::Repository::MockDBv2::Tables::People;
use parent 'Test::PONAPI::DAO::Repository::MockDBv2::DBI';

__PACKAGE__->set_table('people');

__PACKAGE__->columns(Primary   => qw/id/);
__PACKAGE__->columns(Essential => qw/ id name age gender /);

__PACKAGE__->has_many(
    articles => [
        'Test::PONAPI::DAO::Repository::MockDBv2::Tables::ArticlesToPeople'
            => 'id_articles'
    ],
    'id_people',
);

sub create_sql {
    return q<
        id            INTEGER     PRIMARY KEY,
        name          CHAR(64)    NOT NULL   DEFAULT "anonymous",
        age           INTEGER     NOT NULL   DEFAULT "100",
        gender        CHAR(10)    NOT NULL   DEFAULT "unknown"
    >;
}

my @columns_for_insert = qw/id name age gender/;
foreach my $data (
    [42, "John",  80, "male"],
    [88, "Jimmy", 18, "male"],
    [91, "Diana", 30, "female"],
)
{
    my %insert;
    @insert{@columns_for_insert} = @$data;
    __PACKAGE__->insert(\%insert);
}

1;
__END__
