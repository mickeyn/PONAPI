package Test::PONAPI::DAO::Repository::MockDBv2::Tables::Comments;
use parent 'Test::PONAPI::DAO::Repository::MockDBv2::DBI';

__PACKAGE__->set_table('comments');

__PACKAGE__->columns(Primary   => qw/id/);
__PACKAGE__->columns(Essential => qw/body/);

__PACKAGE__->has_many(
    articles => [
        'Test::PONAPI::DAO::Repository::MockDBv2::Tables::ArticlesToComments'
            => 'id_articles'
    ],
    'id_comments',
    { one_to_one => 1 },
);

sub create_sql {
    return q<
             id            INTEGER     PRIMARY KEY,
             body          TEXT        NOT NULL DEFAULT "" 
    >;
}

my @columns_for_insert = qw/id body/;
foreach my $data (
    [5, "First!"],
    [12, "I like XML better"],
)
{
    my %insert;
    @insert{@columns_for_insert} = @$data;
    __PACKAGE__->insert(\%insert);
}

1;
__END__
