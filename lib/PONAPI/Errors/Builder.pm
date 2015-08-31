package PONAPI::Errors::Builder;
# ABSTRACT: A Perl implementation of the JASON-API (http://jsonapi.org/format) spec - Errors

use strict;
use warnings;
use Moose;

with qw<
    PONAPI::Role::Meta
    PONAPI::Role::Links
>;

has id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
    writer    => 'set_id',
);

has status => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_status',
    writer    => 'set_status',
);

has code => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_code',
    writer    => 'set_code',
);

has title => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_title',
    writer    => 'set_title',
);

has detail => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_detail',
    writer    => 'set_detail',
);

has source => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles => {
        has_source => 'count',
    }
);

sub add_source {
    my $self = shift;
    my @args = @_;

    @args > 0 and @args % 2 == 0
        or die "[__PACKAGE__] add_source: arguments list must be key/value pairs";

    while ( @args ) {
        my ($k, $v) = (shift @args, shift @args);
        $self->source->{$k} = $v;
    }

    return $self;
}

sub build {
    my $self = shift;
    my %ret;

    $self->has_id     and $ret{id}     = $self->id;
    $self->has_status and $ret{status} = $self->status;
    $self->has_code   and $ret{code}   = $self->code;
    $self->has_title  and $ret{title}  = $self->title;
    $self->has_detail and $ret{detail} = $self->detail;
    $self->has_source and $ret{source} = $self->source;
    $self->has_links  and $ret{links}  = $self->_links;
    $self->has_meta   and $ret{meta}   = $self->_meta;

    return \%ret;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 id



=head2 type



=head2 attributes



=head2 relationships



=head2 links



=head2 meta

