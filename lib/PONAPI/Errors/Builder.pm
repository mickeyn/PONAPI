package PONAPI::Errors::Builder;
use Moose;

with 'PONAPI::Builder';

has '_errors' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[ HashRef ]',
    lazy    => 1,
    default => sub { +[] },
    handles => {
        'has_errors' => 'count',
        # private ...
        '_add_error' => 'push',
    }
);

sub add_error {
    my $self  = $_[0];
    my $error = $_[1];

    $self->_add_error( $error );
}

sub build {
    my $self   = $_[0];
    my $result = [];
    @$result = @{ $self->_errors };
    return $result;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;