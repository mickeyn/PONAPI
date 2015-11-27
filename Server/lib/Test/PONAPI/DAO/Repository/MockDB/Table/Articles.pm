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
        rel_table => 'rel_articles_people',
        one_to_one => 1,
    },
    comments => {
        type      => 'comments',
        rel_table => 'rel_articles_comments'
    },
};

extends 'Test::PONAPI::DAO::Repository::MockDB::Table';

use PONAPI::DAO::Constants;

override update_stmt => sub {
    my ($self, %args) = @_;

    my $values   = $args{values} || {};
    my $copy = { %$values };
    $copy->{updated} = \'CURRENT_TIMESTAMP';

    my ($stmt, $ret, $msg) = $self->SUPER::update_stmt(%args, values => $copy);
    $ret ||= PONAPI_UPDATED_EXTENDED;
    return $stmt, $ret, $msg;
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
