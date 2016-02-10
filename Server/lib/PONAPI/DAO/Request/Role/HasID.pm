# ABSTRACT: DAO request role - `id`
package PONAPI::DAO::Request::Role::HasID;

use Moose::Role;

has id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
);

sub _validate_id {
    my $self = shift;

    $self->_bad_request( "`id` is missing for this request" )
        unless $self->has_id;
}

no Moose::Role; 1;

__END__
