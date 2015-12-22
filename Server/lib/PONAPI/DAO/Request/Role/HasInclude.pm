# ABSTRACT: DAO request role - `include`
package PONAPI::DAO::Request::Role::HasInclude;

use Moose::Role;

has include => (
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { +[] },
    handles  => {
        "has_include" => 'count',
    },
);

sub _validate_include {
    my $self = shift;
    my $type = $self->type;

    return $self->_bad_request( "`include` is missing values" )
        unless $self->has_include >= 1;

    for ( @{ $self->include } ) {
        $self->repository->has_relationship( $type, $_ )
            or $self->_bad_request( "Types `$type` and `$_` are not related", 404 );
    }
}

no Moose::Role; 1;

__END__
