package Catalyst::Restarter::Forking;

use Moose;

use threads;
use Thread::Cancel;

extends 'Catalyst::Restarter';

has _child => (
    is  => 'rw',
    isa => 'Int',
);


sub _fork_and_start {
    my $self = shift;

    if ( my $pid = fork ) {
        $self->_child($pid);
    }
    else {
        $self->start_sub->();
    }
}

sub _kill_child {
    my $self = shift;

    return unless $self->_child;

    return unless kill 0, $self->_child;

    local $SIG{CHLD} = 'IGNORE';
    die "Cannot send INT signal to ", $self->_child, ": $!"
        unless kill 'INT', $self->_child;
}

1;
