package PONAPI::Builder::Role::HasLinksBuilder;
use Moose::Role;

use PONAPI::Builder::Links;

has 'links_builder' => ( 
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

1;