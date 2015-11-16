package Test::PONAPI::DAO::Repository::MockDB::Table::People;
use Moose;

use constant TYPE   => 'people';
use constant TABLE  => 'people';

use constant COLUMNS => [qw[
    id
    name
    age
    gender
]];

use constant RELATIONS => {
    articles => {
        type      => 'articles',
        rel_table => 'rel_articles_people'
    },
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
