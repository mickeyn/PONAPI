package PONAPI::DAO::Repository::Mock;
use Moose;

with 'PONAPI::DAO::Repository';

has 'rel_spec' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'data' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub has_type {
    my ($self, $type) = @_;
    !! exists $self->data->{ $type };
}

sub has_relationship {
    my ($self, $type, $rel_name) = @_;

    my $spec = $self->rel_spec;
    return 0 unless exists $spec->{ $type };
    return 0 unless exists $spec->{ $type }->{ $rel_name };
    return $spec->{ $type }->{ $rel_name };
}

sub retrieve_all {
    my ($self, %args) = @_;    

    my $doc     = $args{document};
    my $type    = $args{type};
    my $include = $args{include};
    my $data    = $self->data;

    exists $data->{$type} or return die( "type $type doesn't exist" );

    my $id_filter = exists $args{filter}{id} ? delete $args{filter}{id} : undef;

    my @ids = $id_filter
        ? grep { exists $data->{$type}{$_} } @{ $id_filter }
        : keys %{ $data->{$type} };

    # TODO: apply other filters

    $self->_add_resource( $doc, $type, $_, 0, $include ) foreach @ids;    
}

sub retrieve {
    my ($self, %args) = @_;

    my $doc     = $args{document};
    my $type    = $args{type};
    my $id      = $args{id};
    my $include = $args{include};
    my $data    = $self->data;

    exists $data->{$type} or return die( "type $type doesn't exist" );

    unless ( exists $data->{$type}{$id} ) {
        $doc->add_null_resource(undef);
        return;
    }

    $self->_add_resource( $doc, $type, $id, 0, $include );    
}

sub retrieve_relationship {
    my ($self, %args) = @_;

    my $doc      = $args{document};
    my $type     = $args{type};
    my $id       = $args{id};
    my $rel_type = $args{rel_type};
    my $rel_only = $args{rel_only};

    $self->_retrieve_relationships( %args );     
}

sub retrieve_by_relationship {
    my ($self, %args) = @_;

    my $doc      = $args{document};
    my $type     = $args{type};
    my $id       = $args{id};
    my $rel_type = $args{rel_type};
    my $rel_only = $args{rel_only};

    $self->_retrieve_relationships( %args );     
}

sub create {
    my ($self, %args) = @_;

    my ( $type, $data ) = @args{qw< type data >};
    $type or die( "type $type doesn't exist" );
    $data and ref($data) eq 'HASH' or die( "can't create a resource without data" );

    # TODO: create the resource
}

sub update {
    my ($self, %args) = @_;

    my ( $type, $id, $data ) = @args{qw< type id data >};
    $type or die( "can't update a resource without a 'type'" );
    $id   or die( "can't update a resource without an 'id'"  );
    $data or die( "can't update a resource without data"     );

    # TODO: update the resource

}

sub delete : method {
    my ($self, %args) = @_;

    my ( $type, $id ) = @args{qw< type id >};
    $type or die( "can't delete a resource without a 'type'" );
    $id   or die( "can't delete a resource without an 'id'"  );

    # TODO: delte the resource

}

## --------------------------------------------------------
    
sub _add_resource {
    my ( $self, $doc, $type, $id, $identifier_only, $include ) = @_;

    my $data     = $self->data;
    my $resource = $doc->add_resource( type => $type, id => $id );

    return if $identifier_only;

    $resource->add_attributes( %{ $data->{$type}{$id}{attributes} } )
        if keys %{ $data->{$type}{$id}{attributes} };

    return unless exists $data->{$type}{$id}{relationships};

    my %relationships = %{ $data->{$type}{$id}{relationships} };
    for my $k ( keys %relationships ) {
        $resource->add_relationship( $k => $relationships{$k} );

        my ( $t, $i ) = @{ $relationships{$k} }{qw< type id >};

        if ( $include and exists $include->{$k} and exists $data->{$t}{$i} ) {
            my $included = $doc->add_included( type => $t, id => $i );
            $included->add_attributes( %{ $data->{$t}{$i}{attributes} } )
                if exists $data->{$t}{$i}{attributes};
        }
    }
}

sub _retrieve_relationships {
    my ($self, %args) = @_;

    my $data = $self->data;

    my ( $type, $id, $rel_type ) = @args{qw< type id rel_type >};
    exists $data->{$type}      or die( "type $type doesn't exist" );
    exists $data->{$type}{$id} or die( "id $id doesn't exist" );
    exists $data->{$type}{$id}{relationships} or die( "resource has no relationships" );

    my $relationships = $data->{$type}{$id}{relationships}{$rel_type};
    $relationships or die( "relationships type $rel_type doesn't exist" );

    ref($relationships) eq 'ARRAY'
        and return $self->_retrieve_relationships_collection( %args, relationships => $relationships );

    return $self->_retrieve_relationships_single_resource( %args, relationships => $relationships );
}

sub _retrieve_relationships_single_resource {
    my ($self, %args) = @_;
    my $rel = $args{relationships};

    my $doc = $args{document};
    $self->_add_resource( $doc, $rel->{type}, $rel->{id}, $args{rel_only} );
}

sub _retrieve_relationships_collection {
    my ($self, %args) = @_;
    my $rel = $args{relationships};

    my $doc = $args{document};
    $self->_add_resource( $doc, $_->{type}, $_->{id}, $args{rel_only} ) for @{$rel};
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

