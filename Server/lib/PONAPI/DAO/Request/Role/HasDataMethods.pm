package PONAPI::DAO::Request::Role::HasDataMethods;

use Moose::Role;

sub check_has_data {
    my $self = shift;

    return $self->_bad_request( "request body is missing `data`" )
        unless $self->has_data;

    return 1;
}

sub check_data_has_type {
    my $self = shift;

    for ( $self->_get_data_elements ) {
        return $self->_bad_request( "conflict between the request type and the data type" )
            unless exists $_->{'type'};
    }

    return 1;
}

sub check_data_type_match {
    my $self = shift;

    for ( $self->_get_data_elements ) {
        return $self->_bad_request( "conflict between the request type and the data type", 409 )
            unless $_->{'type'} eq $self->type;
    }

    return 1;
}

sub _validate_data {
    my $self = shift;
    return unless $self->has_data;

    $self->_validate_data_attributes();
    $self->_validate_data_relationships();
}

sub _validate_data_attributes {
    my $self = shift;
    my $type = $self->type;

    for my $e ( $self->_get_data_elements ) {
        next unless $e and exists $e->{attributes};
        $self->repository->type_has_fields( $type, [ keys %{ $e->{'attributes'} } ] )
            or return $self->_bad_request(
                "Type `$type` does not have at least one of the attributes in data"
            );
    }

    return 1;
}

sub _validate_data_relationships {
    my $self = shift;
    my $type = $self->type;

    for my $e ( $self->_get_data_elements ) {
        next unless $e and exists $e->{relationships};

        if ( %{ $e->{relationships} } ) {
            for my $rel_type ( keys %{ $e->{relationships} } ) {
                if ( !$self->repository->has_relationship( $type, $rel_type ) ) {
                    return $self->_bad_request(
                        "Types `$type` and `$rel_type` are not related",
                        404
                    );
                }
                elsif ( !$self->repository->has_one_to_many_relationship( $type, $rel_type )
                        and ref $e->{relationships}{$rel_type} eq 'ARRAY'
                        and @{ $e->{relationships}{$rel_type} } > 1
                    ) {
                    return $self->_bad_request(
                        "Types `$type` and `$rel_type` are one-to-one, but got multiple values"
                    );
                }
            }
        }
    }

    return 1;
}

sub _get_data_elements {
    my $self = shift;
    return ( ref $self->data eq 'ARRAY' ? @{ $self->data } : $self->data );
}


no Moose::Role; 1;
__END__
