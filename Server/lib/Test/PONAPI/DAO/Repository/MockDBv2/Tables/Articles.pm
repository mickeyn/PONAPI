package Test::PONAPI::DAO::Repository::MockDBv2::Tables::Articles;
use strict; use warnings;
use parent 'Test::PONAPI::DAO::Repository::MockDBv2::DBI';

__PACKAGE__->set_table('articles');

__PACKAGE__->columns(Primary => qw/id/);
__PACKAGE__->columns(All     => qw/title body created updated status/);

__PACKAGE__->has_many(
    comments => [
        'Test::PONAPI::DAO::Repository::MockDBv2::Tables::ArticlesToComments'
            => 'id_comments'
    ],
    'id_articles',
);

__PACKAGE__->has_many(
    authors => [
        'Test::PONAPI::DAO::Repository::MockDBv2::Tables::ArticlesToPeople'
            => 'id_people'
    ],
    'id_articles',
    { one_to_one => 1 },
);

sub create_sql {
    return q<
        id            INTEGER     PRIMARY KEY AUTOINCREMENT,
        title         CHAR(64)    NOT NULL,
        body          TEXT        NOT NULL,
        created       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
        updated       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
        status        CHAR(10)    NOT NULL   DEFAULT "pending approval"
    >
}

my @columns_for_insert = qw/title body created updated status/;
foreach my $data (
    ["JSON API paints my bikeshed!", "The shortest article. Ever.",
        "2015-05-22 14:56:29", "2015-05-22 14:56:29", "ok" ],
    ["A second title", "The 2nd shortest article. Ever.",
        "2015-06-22 14:56:29", "2015-06-22 14:56:29", "ok" ],
    ["a third one", "The 3rd shortest article. Ever.",
        "2015-07-22 14:56:29", "2015-07-22 14:56:29", "pending approval" ],
)
{
    my %insert;
    @insert{@columns_for_insert} = @$data;
    __PACKAGE__->insert(\%insert);
}

1;

BEGIN{
package Test::PONAPI::DAO::Repository::MockDBv2::Tables::ArticlesToPeople;
use strict; use warnings;
use parent 'Test::PONAPI::DAO::Repository::MockDBv2::DBI';

__PACKAGE__->set_table('rel_articles_people');

__PACKAGE__->columns(Primary => qw/id_articles id_people/);
__PACKAGE__->has_a(
    id_people => 'Test::PONAPI::DAO::Repository::MockDBv2::Tables::People',
);
__PACKAGE__->has_a(
    id_articles => 'Test::PONAPI::DAO::Repository::MockDBv2::Tables::Articles',
);

sub create_sql {
    return q<
             id_articles   INTEGER     NOT NULL PRIMARY KEY,
             id_people     INTEGER     NOT NULL
    >   
}

__PACKAGE__->insert({
    id_articles => $_->[0],
    id_people   => $_->[1],
}) for [1, 42], [2, 88], [3, 91];

package Test::PONAPI::DAO::Repository::MockDBv2::Tables::ArticlesToComments;
use strict; use warnings;
use parent 'Test::PONAPI::DAO::Repository::MockDBv2::DBI';

__PACKAGE__->set_table('rel_articles_comments');

__PACKAGE__->columns(Primary => qw/id_articles id_comments/);

__PACKAGE__->has_a(
    id_comments => 'Test::PONAPI::DAO::Repository::MockDBv2::Tables::Comments',
);
__PACKAGE__->has_a(
    id_articles => 'Test::PONAPI::DAO::Repository::MockDBv2::Tables::Articles',
);

sub create_sql {
    return q<
             id_articles   INTEGER     NOT NULL,
             id_comments   INTEGER     UNIQUE     NOT NULL
    >
}

for ([2, 5], [2, 12]) {
    my $o = __PACKAGE__->insert({
        id_articles => $_->[0],
        id_comments => $_->[1],
    });
}
}
1;
__END__
