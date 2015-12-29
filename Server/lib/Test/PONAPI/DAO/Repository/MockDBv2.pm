package Test::PONAPI::DAO::Repository::MockDBv2;
use Moose;

use Test::PONAPI::DAO::Repository::MockDBv2::Tables::Articles;
use Test::PONAPI::DAO::Repository::MockDBv2::Tables::Comments;
use Test::PONAPI::DAO::Repository::MockDBv2::Tables::People;

has tables => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        return +{
            articles =>
                'Test::PONAPI::DAO::Repository::MockDBv2::Tables::Articles',
            comments =>
                'Test::PONAPI::DAO::Repository::MockDBv2::Tables::Comments',
            people =>
                'Test::PONAPI::DAO::Repository::MockDBv2::Tables::People',
        };
    }
);

with 'PONAPI::DAO::Repository::Class::DBI';

sub _validate_page {
    my ($self, $page) = @_;
    return {} unless %{$page||{}};

    exists $page->{limit}
        or PONAPI::DAO::Exception->throw(message => "Limit missing for `page`");

    $page->{limit} =~ /\A[0-9]+\z/
        or PONAPI::DAO::Exception->throw(message => "Bad limit value ($page->{limit}) in `page`");

    !exists $page->{offset} || ($page->{offset} =~ /\A[0-9]+\z/)
        or PONAPI::DAO::Exception->throw(message => "Bad offset value in `page`");

    $page->{offset} ||= 0;

    return $page;
}

sub _next_page_info {
    my ($self, $page, $rows_fetched) = @_;

    my ($offset, $limit) = @{$page}{qw/offset limit/};

    my %current = %$page;
    my %first = ( %current, offset => 0, );
    my (%previous, %next);

    if ( ($offset - $limit) >= 0 ) {
        %previous = %current;
        $previous{offset} -= $current{limit};
    }

    if ( $rows_fetched >= $limit ) {
        %next = %current;
        $next{offset} += $limit;
    }

    return (
        first => \%first,
        self  => \%current,
        prev  => \%previous,
        next  => \%next,
    );
}

1;
