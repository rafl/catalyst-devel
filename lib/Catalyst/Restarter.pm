package Catalyst::Restarter;

use Moose;

use Catalyst::Watcher;
use File::Spec;
use FindBin;
use namespace::clean -except => 'meta';

has restart_sub => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has _watcher => (
    is  => 'rw',
    isa => 'Catalyst::Watcher',
);

has _child => (
    is  => 'rw',
    isa => 'Int',
);

sub BUILD {
    my $self = shift;
    my $p    = shift;

    delete $p->{restart_sub};

    # We could make this lazily, but this lets us check that we
    # received valid arguments for the watcher up front.
    $self->_watcher( Catalyst::Watcher->new( %{$p} ) );
}

sub run_and_watch {
    my $self = shift;

    $self->_fork_and_start;

    return unless $self->_child;

    $self->_restart_on_changes;
}

sub _fork_and_start {
    my $self = shift;

    if ( my $pid = fork ) {
        $self->_child($pid);
    }
    else {
        $self->restart_sub->();
    }
}

sub _restart_on_changes {
    my $self = shift;

    my $watcher = $self->_watcher;

    while (1) {
        my @files = $watcher->find_changed_files
            or next;

        print STDERR "Saw changes to the following files:\n";
        print STDERR " - $_->{file} ($_->{status})\n" for @files;
        print STDERR "\n";
        print STDERR "Attempting to restart the server\n\n";

        if ( $self->_child ) {
            kill 2, $self->_child
                or die "Cannot send INT to child (" . $self->_child . "): $!";
        }

        $self->_fork_and_start;

        return unless $self->_child;
    }
}

sub DEMOLISH {
    my $self = shift;

    if ( $self->_child ) {
        kill 2, $self->_child;
    }
}

__PACKAGE__->meta->make_immutable;

1;
