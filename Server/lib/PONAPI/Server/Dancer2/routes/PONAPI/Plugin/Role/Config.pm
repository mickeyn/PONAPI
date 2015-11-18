package PONAPI::Plugin::Role::Config;

use Moo::Role;

sub ponapi_config_get_server_sort {
    my $dsl = shift;

    # force explicit setting of 'sort' support configuration
    my $config_sort = $dsl->config->{ponapi}{server}{supports_sort};
    defined $config_sort
        or die "[PONAPI] missing config: {ponapi}{server}{supports_sort}";

    grep { lc($config_sort) eq $_ } qw< 1 true yes >
        and return 1;

    grep { lc($config_sort) eq $_ } qw< 0 false no >
        or die "[PONAPI] invalid config: {ponapi}{server}{supports_sort}";

    return 0;
}

no Moo::Role; 1;
__END__
