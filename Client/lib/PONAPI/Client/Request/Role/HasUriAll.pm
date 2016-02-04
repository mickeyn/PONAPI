# ABSTRACT: request - role - URI format for all-resources requests
package PONAPI::Client::Request::Role::HasUriAll;

use Moose::Role;

has uri_template => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/{type}' },
);

sub path   {
    my $self = shift;
    return +{ type => $self->type };
}

no Moose::Role; 1;

__END__
