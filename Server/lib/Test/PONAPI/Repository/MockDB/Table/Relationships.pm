# ABSTRACT: mock repository - table - Relationships
package Test::PONAPI::Repository::MockDB::Table::Relationships;

use Moose;

extends 'Test::PONAPI::Repository::MockDB::Table';

has REL_ID_COLUMN => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has ONE_TO_ONE => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose; 1

__END__
