# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Builder;
use Moose::Role;

requires 'build';

has 'parent' => (
    is        => 'ro',
    does      => 'PONAPI::Builder',
    predicate => 'has_parent',
    weak_ref  => 1,
);

sub is_root { ! $_[0]->has_parent }

sub find_root {
    my $current = $_[0];
    $current = $current->parent until $current->is_root;
    return $current;
}

sub raise_error {
    my $self   = shift;
    my $status = shift;

    # XXX:
    # we could check the args here and look for
    # a `level` key which would tell us if we
    # should throw an exception (immediate, fatal error)
    # or we should just stash the error and continue.
    # It might get funky, but it would be nice to
    # unify some error handling, maybe, perhaps
    # I am not sure.
    # - SL

    $self->find_root->errors_builder->add_error( @_, status => $status );

    # set given status, on multiple errors use 500/400
    if ( $self->has_errors > 1 and $self->status < 500 ) {
        $self->set_status( ($status >= 500 ? 500 : 400) );
    }
    else {
        $self->set_status($status);
    }

    # we don't return value to allow condition
    # check when returned from validation methods
    return;
}

no Moose::Role; 1;
