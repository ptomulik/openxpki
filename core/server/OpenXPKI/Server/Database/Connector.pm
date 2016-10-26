package OpenXPKI::Server::Database::Connector;
use Moose;
use utf8;
=head1 Name

OpenXPKI::Server::Database::Connector - Handles database connections and
encapsulates DB specific drivers/functions.

=cut

use OpenXPKI::Debug;
use OpenXPKI::Exception;
use DBIx::Handler;
use DBI::Const::GetInfoType; # provides %GetInfoType hash

################################################################################
# Attributes
#

has 'db_params' => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has 'driver' => (
    is => 'ro',
    does => 'OpenXPKI::Server::Database::DriverRole',
    lazy => 1,
    builder => '_build_driver',
);

has 'db_version' => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    builder => '_build_db_version'
);

has '_dbix_handler' => (
    is => 'rw',
    isa => 'DBIx::Handler',
    lazy => 1,
    builder => '_build_dbix_handler',
    handles => {
        start_txn => 'txn_begin',
        commit => 'txn_commit',
        rollback => 'txn_rollback',
    },
);

################################################################################
# Builders
#

sub _build_driver {
    my $self = shift;
    my %args = %{$self->db_params}; # copy hash

    my $driver = $args{type};
    OpenXPKI::Exception->throw (
        message => "Parameter 'type' missing: it must equal the last part of a package in the OpenXPKI::Server::Database::Driver::* namespace.",
    ) unless $driver;
    delete $args{type};

    my $class = "OpenXPKI::Server::Database::Driver::".$driver;

    eval { use Module::Load; autoload($class) };
    OpenXPKI::Exception->throw (
        message => "Unable to require() database driver package",
        params => { class_name => $class, message => $@ }
    ) if $@;

    my $instance;
    eval { $instance = $class->new(%args) };
    OpenXPKI::Exception->throw (
        message => "Unable to instantiate database driver class",
        params => { class_name => $class, message => $@ }
    ) if $@;

    OpenXPKI::Exception->throw (
        message => "Database driver class does not seem to be a Moose class",
        params => { class_name => $class }
    ) unless $instance->can('does');

    OpenXPKI::Exception->throw (
        message => "Database driver class does not consume role OpenXPKI::Server::Database::DriverRole",
        params => { class_name => $class }
    ) unless $instance->does('OpenXPKI::Server::Database::DriverRole');

    return $instance;
}

sub _build_db_version {
    my $self = shift;
    my $db_version = $self->dbh->get_info($GetInfoType{SQL_DBMS_VER});
    ##! 4: "Database version: $db_version"
    return $db_version;
}

sub _build_dbix_handler {
    my $self = shift;
    ##! 4: "DSN: ".$self->_dsn
    ##! 4: "User: ".$self->user
    ##! 4: "Additional connect() attributes: " . join " | ", map { $_." = ".$self->dbi_connect_attrs->{$_} } keys %{$self->dbi_connect_attrs}
    return DBIx::Handler->new(
        $self->driver->dbi_dsn,
        $self->driver->user,
        $self->driver->passwd,
        {
            RaiseError => 1,
            AutoCommit => 0,
            %{$self->driver->dbi_connect_params},
        }
    );
}

################################################################################
# Methods
#

sub dbh {
    my $self = shift;
    # If this is too slow due to DB pings, we could pass "no_ping" attribute to
    # DBIx::Handler and copy the "fixup" code from DBIx::Connector::_fixup_run()
    my $dbh = $self->_dbix_handler->dbh;     # fork safe DBI handle
    $dbh->{FetchHashKeyName} = 'NAME_lc';    # enforce lowercase names
    return $dbh;
}

__PACKAGE__->meta->make_immutable;

=head1 Synopsis

=head1 Description

By returning an instance for a given driver name this class allows you to
include new DBMS specific drivers without the need to change existing code. All
you need to do is writing a driver class that consumes the Moose role
L<OpenXPKI::Server::Database::DriverRole> and then reference it in your config.

=head1 Attributes

=head2 Constructor parameters

=over

=item * B<db_params> - all parameters required by the specific driver class (I<HashRef>, required)

=back

=head2 Others

=over

=item * B<driver> - database specific driver instance (consumer of L<OpenXPKI::Server::Database::DriverRole>)

=item * B<db_version> - Database version, automatically set to the result of C<$dbh-E<gt>get_version(...)>' (I<Str>)

=back

=head2 Methods

=head2 dbh

Returns a fork safe DBI handle.

To remain fork safe DO NOT CACHE this (also do not convert into a lazy attribute).

=cut
