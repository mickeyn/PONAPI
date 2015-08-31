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
        has_errors  => 'count',
    },
);

sub add_error {
    my $self = shift;
    my $args = shift;

    $args and ref $args eq 'HASH'
        or die "[__PACKAGE__] add_error: args must be a hashref";

    my %valid_args = map { $_ => 1 } qw< id status code title detail >;

    my %validated_args;

    for ( keys %{ $args } ) {
        exists $valid_args{$_} and $validated_args{$_} = $args->{$_};
    }

    my $err_builder = PONAPI::Errors::Builder->new( %validated_args );
    $args->{source} and $err_builder->add_source( $args->{source} );

    push @{ $self->_errors } => $err_builder->build;

    return $self;
}

1;

__END__
