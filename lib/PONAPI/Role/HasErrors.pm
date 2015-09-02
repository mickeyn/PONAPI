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

sub add_errors {
    my $self = shift;
    my @args = @_;

    for my $arg ( @args ) {
        $arg and ref $arg eq 'HASH'
            or die "[__PACKAGE__] add_error: arg must be a hashref";

        my %valid_args = map { $_ => 1 } qw< id status code title detail >;

        my %validated_args;

        for ( keys %{ $arg } ) {
            exists $valid_args{$_} and $validated_args{$_} = $arg->{$_};
        }

        my $err_builder = PONAPI::Errors::Builder->new( %validated_args );
        $arg->{source} and $err_builder->add_source( $arg->{source} );
        $arg->{links}  and $err_builder->add_links( $arg->{links} );

        push @{ $self->_errors } => $err_builder->build;
    }

    return $self;
}

1;

__END__
