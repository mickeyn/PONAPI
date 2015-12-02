package PONAPI::DAO::Constants;

my $constants;
BEGIN {
    $constants = {
        PONAPI_OK               => 200,

        PONAPI_UPDATED_EXTENDED => 100,
        PONAPI_UPDATED_NORMAL   => 101,
        PONAPI_UPDATED_NOTHING  => 102,

        PONAPI_ERROR            => 900,
        PONAPI_CONFLICT_ERROR   => 901,
        PONAPI_UNKNOWN_RESOURCE_IN_DATA => 902,
        PONAPI_UNKNOWN_RELATIONSHIP => 903,
        PONAPI_BAD_DATA             => 904,
    };

    require constant; constant->import($constants);
    require Exporter; our @ISA = qw(Exporter);
    our @EXPORT = ( keys %$constants,
        qw/
            %PONAPI_RETURN
            %PONAPI_ERROR_RETURN
            %PONAPI_UPDATE_RETURN_VALUES
        /,
    );
}

our (%PONAPI_UPDATE_RETURN_VALUES, %PONAPI_ERROR_RETURN, %PONAPI_RETURN);
%PONAPI_RETURN = map +($_=>1), values %$constants;
$PONAPI_ERROR_RETURN{+PONAPI_CONFLICT_ERROR}            = 1;
$PONAPI_ERROR_RETURN{+PONAPI_ERROR}                     = 1;
$PONAPI_ERROR_RETURN{+PONAPI_UNKNOWN_RESOURCE_IN_DATA}  = 1;
$PONAPI_ERROR_RETURN{+PONAPI_UNKNOWN_RELATIONSHIP}      = 1;
$PONAPI_ERROR_RETURN{+PONAPI_BAD_DATA}                  = 1;

$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_EXTENDED}  = 1;
$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_NORMAL}    = 1;
$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_NOTHING}   = 1;
@PONAPI_UPDATE_RETURN_VALUES{keys %PONAPI_ERROR_RETURN} = values %PONAPI_ERROR_RETURN;

1;
__END__
=encoding UTF-8

=head1 NAME

PONAPI::DAO::Constants - Constants used by PONAPI::DAO and PONAPI repositories

=head1 SYNOPSIS

    use PONAPI::DAO::Constants;
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

=head2 PONAPI_ERROR

Some error occurred.

=head2 PONAPI_CONFLICT_ERROR

A data conflict occurred; this can happen when creating or updating a
relationship to a resource that has a unique constraint.

=head2 PONAPI_UNKNOWN_RESOURCE_ERROR

The request included references to an unknown resource.

=head2 PONAPI_UNKNOWN_RELATIONSHIP

The request included references to an unknown relationship.

=head2 PONAPI_CREATED_NORMAL

Not used yet.

=head2 PONAPI_CREATED_EXTENDED

Not used yet.
