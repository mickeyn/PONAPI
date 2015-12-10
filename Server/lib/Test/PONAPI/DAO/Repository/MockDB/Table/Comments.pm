# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package Test::PONAPI::DAO::Repository::MockDB::Table::Comments;

use Moose;

extends 'Test::PONAPI::DAO::Repository::MockDB::Table';

use constant TYPE   => 'comments';
use constant TABLE  => 'comments';

use constant COLUMNS => [qw[
    id
    body
]];

use constant RELATIONS => {
    articles => {
        type      => 'articles',
        rel_table => 'rel_articles_comments'
    },
};

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
