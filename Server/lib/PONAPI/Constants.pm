# ABSTRACT: Constants used by PONAPI::DAO and PONAPI repositories
package PONAPI::Constants;

use strict;
use warnings;

my $constants;
BEGIN {
    $constants = {
        PONAPI_UPDATED_EXTENDED => 100,
        PONAPI_UPDATED_NORMAL   => 101,
        PONAPI_UPDATED_NOTHING  => 102,
    };

    require constant; constant->import($constants);
    require Exporter; our @ISA = qw(Exporter);
    our @EXPORT = ( keys %$constants,
        qw/
            %PONAPI_UPDATE_RETURN_VALUES
        /,
    );
}

our (%PONAPI_UPDATE_RETURN_VALUES);

$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_EXTENDED}  = 1;
$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_NORMAL}    = 1;
$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_NOTHING}   = 1;

1;

__END__
=encoding UTF-8

=head1 SYNOPSIS

    use PONAPI::Constants;
    sub update {
        ...

        return $updated_more_rows_than_requested
               ? PONAPI_UPDATED_EXTENDED
               : PONAPI_UPDATED_NORMAL;
    }

=head1 EXPORTS

=head2 PONAPI_UPDATED_NORMAL

The update-like operation did as requested, as no more.

=head2 PONAPI_UPDATED_EXTENDED

The update-like operation did B<more> than requested; maybe it added rows,
or updated another related table.

=head2 PONAPI_UPDATED_NOTHING

The update-like operation was a no-op.  This can happen in a SQL implementation
when modifying a resource that doesn't exist, for example.
