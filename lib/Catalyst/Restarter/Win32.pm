package Catalyst::Restarter::Win32;

use Moose;
use Proc::Background;

extends 'Catalyst::Restarter';

has _child => (
    is  => 'rw',
    isa => 'Proc::Background',
);


sub run_and_watch {
    my $self = shift;

    $self->_fork_and_start;

    return unless $self->_child;

    $self->_restart_on_changes;
}

sub _fork_and_start {
    my $self = shift;

    # This is totally hack-tastic, and is probably much slower, but it
    # does seem to work.
    my @command = ( $^X, $0, grep { ! /^\-r/ } @ARGV );

    my $child = Proc::Background->new(@command);

    $self->_child($child);
}

sub _kill_child {
    my $self = shift;

    return unless $self->_child;

    $self->_child->die;
}

1;
