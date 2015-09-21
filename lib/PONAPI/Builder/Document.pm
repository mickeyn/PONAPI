package PONAPI::Builder::Document;
use Moose;

use PONAPI::Builder::Resource;
use PONAPI::Builder::Errors;

with 'PONAPI::Builder',
     'PONAPI::Builder::Role::HasLinksBuilder',
     'PONAPI::Builder::Role::HasMeta';

has '_included' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[ PONAPI::Builder::Resource ]',
    lazy    => 1,
    default => sub { +[] },
    handles => {
        'has_included'  => 'count',
        # private ...
        '_add_included' => 'push',
    }
);

sub add_included {
    my ($self, %args) = @_;
    my $builder = PONAPI::Builder::Resource->new( parent => $self, %args );
    $self->_add_included( $builder );
    return $builder;
}

has '_resource_builder' => (
    is        => 'ro',
    isa       => 'PONAPI::Builder::Resource',
    predicate => '_has_resource_builder',
    writer    => '_set_resource_builder',
);

sub has_resource {
    my $self = $_[0];
    $self->_has_resource_builder;
}

sub add_resource {
    my ($self, %args) = @_;
    my $builder = PONAPI::Builder::Resource->new( %args, parent => $_[0] );
    $self->_set_resource_builder( $builder );
    return $builder;
}

has 'errors_builder' => (
    is        => 'ro',
    isa       => 'PONAPI::Builder::Errors',
    lazy      => 1,
    predicate => 'has_errors_builder',
    builder   => '_build_errors_builder',
);

sub _build_errors_builder { PONAPI::Builder::Errors->new( parent => $_[0] ) }

sub build {
    my $self   = $_[0];
    my $result = +{ jsonapi => { version => "1.0" } };

    if ( ! $self->has_errors_builder ) {
        $result->{meta}  = $self->_meta                if $self->has_meta;
        $result->{links} = $self->links_builder->build if $self->has_links_builder;

        if ( $self->_has_resource_builder ) {
            $result->{data}     = $self->_resource_builder->build;
            $result->{included} = +[ map { $_->build } @{ $self->_included } ]
                if $self->has_included;
        }
    }

    if ( $self->has_errors_builder ) {
        return +{
            jsonapi => +{ version => "1.0" },
            errors  => $self->errors_builder->build,
        };
    }

    return $result;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;
