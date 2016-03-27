# ABSTRACT: document builder - role - links
package PONAPI::Document::Builder::Role::HasLinksBuilder;

use Moose::Role;

use PONAPI::Document::Builder::Links;

requires 'add_self_link';

has links_builder => (
    init_arg  => undef,
    is        => 'ro',
    isa       => 'PONAPI::Document::Builder::Links',
    lazy      => 1,
    predicate => 'has_links_builder',
    builder   => '_build_links_builder',
    handles   => [qw[
        has_links
        has_link
    ]]
);

sub _build_links_builder { PONAPI::Document::Builder::Links->new( parent => $_[0] ) }

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

__END__
