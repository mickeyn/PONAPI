package PONAPI::Role::HasErrors;

use strict;
use warnings;

use Moose::Role;

use PONAPI::Errors::Builder;

has _errors => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    default   => sub { +[] },
    handles   => {
        has_errors => 'count',
        get_errors => 'elements',
    },
);

sub add_errors {
    my $self = shift;
    my @args = @_;

    for my $arg ( @args ) {
        $arg and ref $arg eq 'HASH'
            or die "[__PACKAGE__] add_errors: arg must be a hashref\n";

        my %valid_args = map { $_ => 1 } qw< id status code title detail source links >;

        for ( keys %{ $arg } ) {
            exists $valid_args{$_}
                or die "[__PACKAGE__] add_errors: invalid key: $_\n";
        }

        my $err_builder = PONAPI::Errors::Builder->new( @args );
        $arg->{source} and $err_builder->add_source( $arg->{source} );

        push @{ $self->_errors } => $err_builder->build;
    }

    return $self;
}

1;

__END__
