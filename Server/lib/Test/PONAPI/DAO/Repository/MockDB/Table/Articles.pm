package Test::PONAPI::DAO::Repository::MockDB::Table::Articles;
use Moose;

use constant TYPE   => 'articles';
use constant TABLE  => 'articles';

use constant COLUMNS => [qw[
    id
    title
    body
    created
    updated
    status
]];

use constant RELATIONS => {
    authors  => {
        type      => 'people',
        rel_table => 'rel_articles_people'
    },
    comments => {
        type      => 'comments',
        rel_table => 'rel_articles_comments'
    },
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
