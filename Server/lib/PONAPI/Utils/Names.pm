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
=encoding UTF-8

=head1 SYNOPSIS

    use PONAPI::Utils::Names 'check_name';
    
    check_name('a');    # Valid
    check_name('a-');   # Invalid
    check_name('-a');   # Invalid
    check_name('a-b');  # Valid
    check_name('a b');  # Valid


=head1 DESCRIPTION

This module implements the L<member name restrictions|http://jsonapi.org/format/#document-member-names>
from the {json:api} specification; it can be used by repositories
to implement strict member names, if desired.
