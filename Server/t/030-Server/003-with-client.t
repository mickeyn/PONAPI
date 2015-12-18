#!perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;
use Storable qw/dclone/;

use PONAPI::Server;

my $have_client = !!eval { require PONAPI::Client; 1 };
if ( !$have_client ) {
    plan skip_all => 'Client cannot be loaded, not running these tests';
}

use Plack::Test::Server;
my $app = Plack::Test::Server->new(PONAPI::Server->new(
    'ponapi.sort_allowed' => 1
)->to_app());

if ( !$app ) {
    fail('Failed to start a PSGI test server?');
    done_testing;
    exit;
}

my $port   = $app->port;
my $client = do { local $@; eval { PONAPI::Client->new( port => $port ) } };

isa_ok($client, 'PONAPI::Client', '..we can create a client pointing to our test server');

my $article_2 = {
  data => {
    type       => "articles",
    id         => 2,
    links      => { self => "/articles/2" },
    attributes => {
      body    => "The 2nd shortest article. Ever.",
      created => "2015-06-22 14:56:29",
      status  => "ok",
      title   => "A second title",
      updated => "2015-06-22 14:56:29"
    },
    relationships => {
      authors => {
        data => {
          id   => 88,
          type => "people"
        },
        links => {
          related => "/articles/2/authors",
          self    => "/articles/2/relationships/authors"
        }
      },
      comments => {
        data => [
          {
            id   => 5,
            type => "comments"
          },
          {
            id   => 12,
            type => "comments"
          }
        ],
        links => {
          related => "/articles/2/comments",
          self    => "/articles/2/relationships/comments"
        }
      }
    },
  },
  included => [
    {
      attributes => {
        age => 18,
        gender => "male",
        name => "Jimmy"
      },
      id    => 88,
      links => { self => "/people/88" },
      type  => "people"
    },
    {
      type       => "comments",
      id         => 5,
      attributes => { body => "First!"      },
      links      => { self => "/comments/5" },
    },
    {
      type       => "comments",
      id         => 12,
      attributes => { body => "I like XML better" },
      links      => { self => "/comments/12"      },
    }
  ],
  jsonapi => { version => "1.0"         },
  links   => { self    => "/articles/2" },
};

my @common = ( type => articles => id => 2 );
sub basic_retrieve_all_test {
    my ($res, $expected_ids_in_order) = @_;

    my $ids    = join '|', map $_->{id}, @{ $res->{data} };
    my $expect = join '|', @$expected_ids_in_order;

    is($ids, $expect, "retrieve_all works as expected ($expect)")
        or diag(Dumper($res));
}
subtest '... retrieve_all' => sub {
    my $res = $client->retrieve_all(type => 'articles');
    basic_retrieve_all_test($res, [1, 2, 3]);

    my $res_sorted = $client->retrieve_all(type => 'articles', sort => [qw/-id/]);
    basic_retrieve_all_test($res_sorted, [3, 2, 1]);

    my $res_sorted_page = $client->retrieve_all(
        type => 'articles',
        sort => [qw/-id/],
        page => {
            offset => 1,
            limit  => 1,
        },
    );
    basic_retrieve_all_test($res_sorted_page, [2]);
    is_deeply(
        $res_sorted_page->{links},
        {
            'self' => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=1',
            'next' => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=2',
            'first' => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=0',
            'prev' => '/articles?page%5Blimit%5D=1&page%5Boffset%5D=0',
        },
        "... paging works (sort of)"
    ) or diag(Dumper($res_sorted_page));
};

subtest '... retrieve' => sub {
    my $res = $client->retrieve(@common);
    my $clone = dclone $article_2;
    delete $clone->{included};
    is_deeply($res, $clone, "...we retrieved the correct user");

    # Let's test all of the options here.
    my $fields_res = $client->retrieve(@common,
        fields => { articles => [qw/title/] },
    );
    delete $fields_res->{data}{links};
    is_deeply(
        $fields_res->{data},
        {
            @common,
            attributes => { title => "A second title" },
        },
        "... filtering the main resource's attributes works",
    );

    my $fields_rel_res = $client->retrieve(@common,
        fields => { articles => [qw/authors/] },
    );
    delete $fields_rel_res->{data}{relationships}{authors}{links};
    is_deeply(
        $fields_rel_res->{data}{relationships},
        { authors => { data => { type => people => id => 88 } }, },
        "... filtering the main resource's attributes works",
    ) or diag(Dumper($fields_rel_res));

};

subtest '... retrieve_by_relationship' => sub {
    my $res1 = $client->retrieve_by_relationship(@common, rel_type => 'authors');
    delete $res1->{data}{relationships};
    is_deeply(
        [ $res1->{data} ],
        [ grep $_->{type} eq 'people', @{$article_2->{included}} ],
        "... got the right data for a one-to-one"
    ) or diag(Dumper($res1));

    my $res2 = $client->retrieve_by_relationship(@common, rel_type => 'comments');
    delete $_->{relationships} for @{ $res2->{data} };
    is_deeply(
        $res2->{data},
        [ grep $_->{type} eq 'comments', @{$article_2->{included}} ],
        "... got the right data for a one-to-many"
    ) or diag(Dumper($res2));
};

subtest '... retrieve_relationships' => sub {
    my $res1 = $client->retrieve_relationships(@common, rel_type => 'authors');
    is_deeply(
        $res1->{data},
        $article_2->{data}{relationships}{authors}{data},
        "... fetched the correct one-to-one relationship"
    ) or diag(Dumper($res1));

    my $res2 = $client->retrieve_relationships(@common, rel_type => 'comments');
    is_deeply(
        $res2->{data},
        $article_2->{data}{relationships}{comments}{data},
        "... fetched the correct one-to-many relationship",
    ) or diag(Dumper($res2));
};

my $author_attributes = {
    name   => 'New!',
    age    => 11,
    gender => 'female',
};

subtest '... create + update + delete (without relationships)' => sub {
    my $create_res = $client->create(
        type => 'people',
        data => {
            type       => 'people',
            attributes => $author_attributes,
        },
    );
    isa_ok( $create_res->{data}, 'HASH', ".. created and got data back" )
        or diag(Dumper($create_res));

    my $retrieve_res = $client->retrieve( $create_res->{data} );
    is_deeply(
        $retrieve_res->{data}{attributes},
        $author_attributes,
        ".. and we retrieved it just fine",
    ) or diag(Dumper($retrieve_res));

    foreach my $iteration (1..5) {
        my $update_res = $client->update(
            %{ $create_res->{data} },
            data => {
                type       => 'people',
                attributes => { name => 'Another name', },
            },
        );
        like(
            $update_res->{meta}{detail},
            qr/\Asuccessfully modified/,
            ".. updated attributes successfully ( $iteration )"
        );
    }

    my $delete_res = $client->delete( $create_res->{data} );
    like(
        $delete_res->{meta}{detail},
        qr/\Asuccessfully deleted the resource/,
        "... and deleted it"
    );

    my $delete_res_again = $client->delete( $create_res->{data} );
    like(
        $delete_res->{meta}{detail},
        qr/\Asuccessfully deleted the resource/,
        "... and deleted it again, without any issues"
    );
};

sub _get_a_new_author {
    my ($client) = @_;

    return $client->create(
        type => 'people',
        data => {
            type       => 'people',
            attributes => $author_attributes,
        }
    )->{data};
}
sub _get_a_new_comments {
    my ($client) = @_;

    return $client->create(
        type => 'comments',
        data => {
            type => 'comments',
            attributes => { body => "Text yadda " . rand(250) },
        },
    )->{data};
}

subtest '... (update|create|delete)_relationships' => sub {
    # First, let's create an author, two comments,
    # and then add them to articles.
    my $author   = _get_a_new_author($client);
    my @comments = map _get_a_new_comments($client), 1, 2;

    my $article = $client->create(
        type => 'articles',
        data => {
            type => 'articles',
            attributes => {
                title => 'foo',
                body  => 'bar',
            },
        }
    )->{data};

    # Let's add some relationships:
    my $create_rel = $client->create_relationships(
        %$article,
        rel_type => 'comments',
        data     => \@comments,
    );
    like( $create_rel->{meta}{detail}, qr/\Asuccessfully modified/ );

    my $retrieve_rel = $client->retrieve_relationships( %$article, rel_type => 'comments' );
    is_deeply( $retrieve_rel->{data}, \@comments, "... successfully added two comments to the article" );
    my $retrieve_rel_backwards = $client->retrieve_relationships(
        %{$comments[0]}, rel_type => 'articles',
    );
    is_deeply( $retrieve_rel_backwards->{data}, $article, "... and we can fetch the article going by the comments, too" );

    foreach my $iteration (1..5) {
        my ($code, $delete_rel) = $client->delete_relationships(
            %$article,
            rel_type => 'comments',
            data     => [ $comments[0] ],
        );

        if ( !$delete_rel ) {
            is( $code, 204, "... no body, but status is 204, so that's fine (try $iteration)" );
            next;
        }

        my $qr = $iteration == 1
                ? qr/\Asuccessfully modified/
                : qr/\Amodified nothing for/;

        like(
            $delete_rel->{meta}{detail},
            $qr,
            "... delete relationships (try $iteration)"
        );
    }

    # First, try updating the authors, which is one-to-one
    foreach my $test_data (
        [ 'authors' => $author    ],
        [ 'authors' => undef      ],
        [ 'authors' => \@comments ],
        [ 'authors' => []         ],
    )
    {
        my ($rel_type, $data) = @$test_data;
        foreach my $iteration (1..5) {
            my $update_rel = $client->update_relationships(
                %$article, rel_type => 'authors',
                data => $author,
            );

            my $one_to   = ref($data||'') eq 'ARRAY' ? 'one-to-many' : 'one-to-one';
            my $has_data = (!defined($data) || (ref $data eq 'ARRAY' && !@$data))
                         ? 'without data'
                         : 'with data';
            like(
                $update_rel->{meta}{detail},
                qr/\Asuccessfully modified /,
                "... update_relationships ($one_to) works ($rel_type, $has_data, try $iteration)"
            );
        }
    }
};

subtest '... create + update +delete (with relationships)' => sub {
    my $author   = _get_a_new_author($client);
    my @comments = map _get_a_new_comments($client), 1, 2;

    my $create_res = $client->create(
        type => 'articles',
        data => {
            type       => 'articles',
            attributes => {
                title => "Base title",
                body  => "Base body",
            },
        },
        relationships => {
            authors  => $author,
            comments => \@comments,
        }
    );
    like(
        $create_res->{meta}{detail},
        qr/successfully created the resource/,
        "... created the resource"
    ) or diag(Dumper($create_res));

    my $json = JSON::XS->new->allow_nonref->utf8->canonical;
    foreach my $rels (
        { comments => \@comments, authors => $author },
        { comments => [], authors => $author },
        { comments => \@comments, authors => undef },
        { comments => [], authors => undef },
        { comments => [$comments[1]], authors => $author },
        { comments => [], authors => undef },
    )
    {
        foreach my $i (1..5) {
            my $update_res = $client->update(
                %{ $create_res->{data} },
                data => {
                    %{ $create_res->{data} },
                    attributes    => { title => 'Update!' },
                    relationships => $rels,
                }
            );
            my $data_json = $json->encode($rels);
            like(
                $update_res->{meta}{detail},
                qr/\Asuccessfully modified/,
                "... successful update with $data_json (try $i)"
            ) or diag( Dumper($update_res) );
        }
    }
};

done_testing;