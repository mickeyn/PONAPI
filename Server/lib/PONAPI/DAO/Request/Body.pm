package PONAPI::DAO::Request::Body;
use Moose;

has '_data' => (
    init_arg => 'data',
    traits   => [ 'Hash' ],
    is       => 'bare',
    isa      => 'HashRef',
    required => 1,
    handles  => {
        'id'            => [ get => 'id'            ],
        'type'          => [ get => 'type'          ],
        'attributes'    => [ get => 'attributes'    ],
        'relationships' => [ get => 'relationships' ],
    }
);

# NOTES:
# - The `type` is the only thing required
# - No `links`, they are managed by the server
# - No `meta`, that is also server managed
#   - if we have a need to change `meta`, it should be done
#     via a more "meta" channel, such as headers
# - No `jsonapi`, just no need

sub BUILD {
    my $self = $_[0];
    die 'The `type` feild is required'
        if not exists $self->{_data}->{type};

    $self->{_data}->{attributes}    //= +{};
    $self->{_data}->{relationships} //= +{};
}

sub get_attribute_keys { keys %{ $_[0]->attributes }          }
sub get_attribute      {         $_[0]->attributes->{ $_[1] } }
sub has_attribute      {  exists $_[0]->attributes->{ $_[1] } }

sub get_relationship_keys { keys %{ $_[0]->relationships }          }
sub get_relationship      {         $_[0]->relationships->{ $_[1] } }
sub has_relationship      {  exists $_[0]->relationships->{ $_[1] } }

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
