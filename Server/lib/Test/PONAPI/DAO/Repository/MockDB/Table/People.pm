# ABSTRACT: mock repository - table - People
package Test::PONAPI::DAO::Repository::MockDB::Table::People;

use Moose;

extends 'Test::PONAPI::DAO::Repository::MockDB::Table';
use Test::PONAPI::DAO::Repository::MockDB::Table::Relationships;

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    my $to_articles =
        Test::PONAPI::DAO::Repository::MockDB::Table::Relationships->new(
            TYPE          => 'articles',
            TABLE         => 'rel_articles_people',
            ID_COLUMN     => 'id_people',
            REL_ID_COLUMN => 'id_articles',
            COLUMNS       => [qw/ id_articles id_people /],
            ONE_TO_ONE    => 0,
        );

    %args = (
        TYPE      => 'people',
        TABLE     => 'people',
        ID_COLUMN => 'id',
        COLUMNS   => [qw/ id name age gender /],
        RELATIONS => { articles => $to_articles, },
        %args,
    );

    return \%args;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
