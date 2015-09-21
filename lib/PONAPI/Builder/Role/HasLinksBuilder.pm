# ABSTRACT: PONAPI - Perl JSON-API implementation (http://jsonapi.org/) v1.0
package PONAPI::Builder::Role::HasLinksBuilder;
use Moose::Role;

use PONAPI::Builder::Links;

has 'links_builder' => (
    init_arg  => undef,
    is        => 'ro',
    isa       => 'PONAPI::Builder::Links',
    lazy      => 1,
    predicate => 'has_links_builder',
    builder   => '_build_links_builder',
    handles   => [qw[
        has_links
    ]]
);

sub _build_links_builder { PONAPI::Builder::Links->new( parent => $_[0] ) }

# NOTE:
# These need to be delegated so that they
# can return the instance of the Builder
# they are attached to and not the Links
# Builder itself.
# - SL

sub add_link {
    my ($self, @args) = @_;
    $self->links_builder->add_link( @args );
    return $self;
}

sub add_links {
    my ($self, @args) = @_;
    $self->links_builder->add_links( @args );
    return $self;
}

no Moose::Role; 1;
