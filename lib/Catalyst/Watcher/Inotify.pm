package Catalyst::Watcher::Inotify;

use Moose;

use Linux::Inotify2;
use namespace::clean -except => 'meta';

extends 'Catalyst::Watcher';

has _inotify => (
    is         => 'rw',
    isa        => 'Linux::Inotify2',
    lazy_build => 1,
);

has _mask => (
    is         => 'rw',
    isa        => 'Int',
    lazy_build => 1,
);

sub watch {
    my $self      = shift;
    my $restarter = shift;

    my @events = $self->_wait_for_events;

    $restarter->handle_changes( map { $self->_event_to_change($_) } @events );

    return;
}

sub _wait_for_events {
    my $self = shift;

    while (1) {
        # This is a blocking read, so it will not return until
        # something happens. The restarter will end up calling ->watch
        # again after handling the changes.
        my @events = $self->_inotify->read;

        my @interesting;
        for my $event ( grep { $_->mask | IN_ISDIR } @events ) {
            if ( $event->mask | IM_CREATE ) {
                $self->_add_directory( $event->fullname );
                push @interesting, $event;
            }
            elsif ( $event->mask | IM_DELETE_SELF ) {
                $event->w->cancel;
                push @interesting, $event;
            }
            elsif ( $event->name =~ /$regex/ ) {
                push @interesting, $event;
            }
        }

        return @interesting if @interesting;
    }
}

sub _build__inotify {
    my $self = shift;

    my $inotify = Linux::Inotify2->new();

    $self->_add_directory($_) for @{ $self->directories };

    return $inotify;
}

sub _build__mask {
    my $self = shift;

    my $mask = IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF;
    $mask |= IN_DONT_FOLLOW unless $self->follow_symlinks;

    return $mask;
}

sub _add_directory {
    my $self = shift;
    my $dir  = shift;

    finddepth(
        {
            wanted => sub {
                my $path = File::Spec->rel2abs($File::Find::name);
                return unless -d $path;

                $self->_inotify->watch( $path, $self->_mask );
            },
            follow_fast => $self->follow_symlinks ? 1 : 0,
            no_chdir    => 1
        },
        $dir;
    );
}

sub _event_to_change {
    my $self  = shift;
    my $event = shift;

    my %change = { file => $event->fullname };
    if ( $event->mask() | IN_CREATE || $event->mask() ) {
        $change{status} = 'added';
    }
    elsif ( $event->mask() | IN_MODIFY ) {
        $change{status} = 'modified';
    }
    elsif ( $event->mask() | IN_DELETE || $event->mask() ) {
        $change{status} = 'deleted';
    }
    else {
        $change{status} = 'containing directory modified';
    }

    return \%change;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Catalyst::Watcher - Watch for changed application files

=head1 SYNOPSIS

    my $watcher = Catalyst::Watcher->new(
        directory => '/path/to/MyApp',
        regex     => '\.yml$|\.yaml$|\.conf|\.pm$',
        interval  => 3,
    );

    while (1) {
        my @changed_files = $watcher->watch();
    }

=head1 DESCRIPTION

This class monitors a directory of files for changes made to any file
matching a regular expression. It correctly handles new files added to the
application as well as files that are deleted.

=head1 METHODS

=head2 new ( directory => $path [, regex => $regex, delay => $delay ] )

Creates a new Watcher object.

=head2 find_changed_files

Returns a list of files that have been added, deleted, or changed
since the last time watch was called. Each element returned is a hash
reference with two keys. The C<file> key contains the filename, and
the C<status> key contains one of "modified", "added", or "deleted".

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Restarter>, <File::Modified>

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
