# ABSTRACT: document builder - errors
package PONAPI::Document::Builder::Errors;

use Moose;

with 'PONAPI::Document::Builder';

has _errors => (
    init_arg => undef,
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef[ HashRef ]',
    lazy     => 1,
    default  => sub { +[] },
    handles  => {
        'has_errors' => 'count',
        # private ...
        '_add_error' => 'push',
    }
);

sub add_error {
    my ( $self, $error ) = @_;
    $self->_add_error( $error );
}

sub build {
    my $self = $_[0];
    return +[ @{ $self->_errors } ];
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
