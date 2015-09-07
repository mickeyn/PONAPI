package PONAPI::Role::HasMeta;

use strict;
use warnings;

use Moose::Role;

# decided not to support ' ' (space) as it's not recommended (not URL safe)
my $re_member_name = qr{^[a-zA-Z0-9][a-zA-Z0-9_\-]*$};
my $re_member_illegal_chars = qr{[+,.\[\]!'"#$%&()*/:;<=>?@\\^`{|}~]};

has _meta => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        has_meta => 'count',
    }
);

sub add_meta {
    my $self  = shift;
    my @args = @_;

    @args > 0 and @args % 2 == 0
        or die "[__PACKAGE__] add_meta: arguments list must be key/value pairs\n";

    while ( @args ) {
        my ($k, $v) = (shift @args, shift @args);

        $k and !ref($k) and $k =~ /$re_member_name/ and $k !~ /$re_member_illegal_chars/
            or die "[__PACKAGE__] add_meta: invalid member name: $k\n";

        $self->_meta->{$k} = $v;
    }

    return $self;
}


1;

__END__
