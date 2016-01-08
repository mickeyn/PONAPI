# ABSTRACT: Member names validation utility
package PONAPI::Utils::Names;

use parent qw< Exporter >;
@EXPORT_OK = qw< check_name >;

my $qr_edge = qr/[a-zA-Z0-9\P{ASCII}]/;
my $qr_mid  = qr/[a-zA-Z0-9\P{ASCII}_\ -]/;

sub check_name {
    my $name = shift;

    return if ref($name);
    return if length($name) == 0;

    return $name =~ /\A $qr_edge          \z/x if length($name) == 1;
    return $name =~ /\A $qr_edge $qr_edge \z/x if length($name) == 2;
    return $name =~ /\A $qr_edge $qr_mid+ $qr_edge \z/x;
}

1;

__END__
