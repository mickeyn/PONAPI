package PONAPI::DAO::Request::Role::HasRelationshipType;

use Moose::Role;

has rel_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_rel_type',
);

sub _validate_rel_type {
    my $self = shift;

    return $self->_bad_request( "`relationship type` is missing" )
        unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 )
        unless $self->repository->has_relationship( $type, $rel_type );
}

no Moose::Role; 1;
__END__
