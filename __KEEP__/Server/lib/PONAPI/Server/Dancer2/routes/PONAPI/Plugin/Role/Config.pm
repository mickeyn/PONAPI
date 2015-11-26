package PONAPI::Plugin::Role::Config;

use Moo::Role;

sub ponapi_config_get_server_sort {
    my $dsl = shift;

    # force explicit setting of 'sort' support configuration
    my $config_sort = $dsl->config->{ponapi}{server}{sort_allowed};
    defined $config_sort
        or die "[PONAPI] missing config: {ponapi}{server}{sort_allowed}";

    grep { lc($config_sort) eq $_ } qw< 1 true yes >
        and return 1;

    grep { lc($config_sort) eq $_ } qw< 0 false no >
        or die "[PONAPI] invalid config: {ponapi}{server}{sort_allowed}";

    return 0;
}

no Moo::Role; 1;
__END__
