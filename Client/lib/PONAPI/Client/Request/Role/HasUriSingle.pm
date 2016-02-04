# ABSTRACT: request - role - URI format for single-resource requests
package PONAPI::Client::Request::Role::HasUriSingle;

use Moose::Role;

has uri_template => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/{type}/{id}' },
);

sub path   {
    my $self = shift;
    return +{ type => $self->type, id => $self->id };
}

no Moose::Role; 1;

__END__
