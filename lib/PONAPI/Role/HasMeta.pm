package PONAPI::Role::HasMeta;

use strict;
use warnings;

use Moose::Role;

# we don't support ' ' (space) and as as it's not recommended (not URL safe)
my $re_member_first_char    = qr{^[a-zA-Z0-9]};
my $re_member_illegal_chars = qr{[+,.\[\]!'"#$%&()*/:;<=>?@\\^`{|}~\ ]};

has _meta => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        has_meta  => 'count',
        _set_meta => 'set',
    }
);

before _set_meta => sub {
    my $self = shift;
    my %args = @_;

    for ( keys %args ) {
        /$re_member_first_char/ and !/$re_member_illegal_chars/
            or die "[__PACKAGE__] add_meta: invalid member name: $_\n";
    }

    return %args;
};

sub add_meta {
    my $self  = shift;
    my @args = @_;

    @args > 0 and @args % 2 == 0
        or die "[__PACKAGE__] add_meta: arguments list must be key/value pairs\n";

    $self->_set_meta( @args );

    return $self;
}


1;

__END__
