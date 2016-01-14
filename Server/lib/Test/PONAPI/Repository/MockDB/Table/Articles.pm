# ABSTRACT: mock repository - table - Articles
package Test::PONAPI::Repository::MockDB::Table::Articles;

use Moose;
use Test::PONAPI::Repository::MockDB::Table::Relationships;

extends 'Test::PONAPI::Repository::MockDB::Table';

use constant COLUMNS => [qw[
    id
    title
    body
    created
    updated
    status
]];

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    # We could abstract these to their own objects, but no need currently
    my $to_comments =
        Test::PONAPI::Repository::MockDB::Table::Relationships->new(
            TYPE          => 'comments',
            TABLE         => 'rel_articles_comments',
            ID_COLUMN     => 'id_articles',
            REL_ID_COLUMN => 'id_comments',
            COLUMNS       => [qw/ id_articles id_comments /],
            ONE_TO_ONE    => 0,
        );
    my $to_authors =
        Test::PONAPI::Repository::MockDB::Table::Relationships->new(
            TYPE          => 'people',
            TABLE         => 'rel_articles_people',
            ID_COLUMN     => 'id_articles',
            REL_ID_COLUMN => 'id_people',
            COLUMNS       => [qw/ id_articles id_people /],
            ONE_TO_ONE    => 1,
        );

    %args = (
        TYPE      => 'articles',
        TABLE     => 'articles',
        ID_COLUMN => 'id',
        COLUMNS   => COLUMNS(),
        RELATIONS => {
            authors  => $to_authors,
            comments => $to_comments,
        },
        %args,
    );

    return \%args;
}

use PONAPI::Constants;
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
