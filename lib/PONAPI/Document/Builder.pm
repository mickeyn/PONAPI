package PONAPI::Document::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Document

use strict;
use warnings;
use Moose;


has action => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has is_collection => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);


has _data => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    default   => sub { +[] },
    handles   => {
        has_data => 'count',
        add_data => 'push',
    },
);

has _errors => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    default   => sub { +[] },
    handles   => {
        has_errors => 'count',
        add_errors => 'push',
    },
);

has _meta => (
    init_arg => undef,
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
    handles => {
        has_meta => 'count',
        add_meta => 'set',
        get_meta => 'get',
    }
);

has _links => (
    init_arg  => undef,
    is        => 'ro',
    writer    => 'set_links',
    predicate => 'has_links',
);

has _included => (
    init_arg  => undef,
    is        => 'ro',
    writer    => 'set_included',
    predicate => 'has_include',
);


sub BUILDARGS {
    my ( $class, %args ) = @_;

    my $action = delete $args{action};
    my $type   = delete $args{type};

    $action or die "[$class] new: missing action\n";
    $type   or die "[$class] new: missing type\n";

    !ref($action) and grep { $action eq $_ } qw< GET POST PATCH DELETE >
        or die "[$class] new: invalid action\n";

    !ref($type) or die "[$class] new: invalid type\n";

    return +{
        action        => $action,
        type          => $type,
        is_collection => ( exists $args{id} ? 0 : 1 ),
        %args
    };
}

sub add_links {
    my $self  = shift;
    my $links = shift;

    $links and ref($links) eq 'HASH'
        or die "[__PACKAGE__] add_links: invalid links\n";

    $self->set_links( $links );

    return $self;
}

sub add_included {
    my $self  = shift;
    my $included = shift;

    $included and ref($included) eq 'HASH'
        or die "[__PACKAGE__] add_included: invalid included\n";

    $self->set_included( $included );

    return $self;
}


sub build {
    my $self = shift;

    unless ( $self->has_errors or $self->has_data or $self->has_meta ) {
        $self->add_error( +{
            # ...
            detail => "Missing data/meta",
        } );
    }

    # errors -> return object with errors
    if ( $self->has_errors ) {
        return +{
            errors => $self->_errors,
        };
    }

    my %ret = ( jsonapi => { version => "1.0" } );

    if ( $self->has_data ) {
        $ret{data} = $self->is_collection_req
            ? $self->_data
            : $self->_data->[0];

        $self->has_include and $ret{included} = $self->_include;

    } else {
        $ret{data} = $self->is_collection_req ? [] : undef;
    }

    $self->has_meta  and $ret{meta}  = $self->_meta;
    $self->has_links and $ret{links} = $self->links;

    return \%ret;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

