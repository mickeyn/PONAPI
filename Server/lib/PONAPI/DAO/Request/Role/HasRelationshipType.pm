# ABSTRACT: DAO request role - `relationship type`
package PONAPI::DAO::Request::Role::HasRelationshipType;

use Moose::Role;

has rel_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_rel_type',
);

sub _validate_rel_type {
    my ( $self, $args ) = @_;

    return $self->_bad_request( "`relationship type` is missing for this request" )
        unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    if ( !$self->repository->has_relationship( $type, $rel_type ) ) {
        return $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 )
    }
}

no Moose::Role; 1;

__END__
