# ABSTRACT: request - role - URI format for relationships requests
package PONAPI::Client::Request::Role::HasUriRelationships;

use Moose::Role;

has uri_template => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/{type}/{id}/relationships/{rel_type}' },
);

sub path   {
    my $self = shift;
    return +{ type => $self->type, id => $self->id, rel_type => $self->rel_type };
}

no Moose::Role; 1;

__END__
