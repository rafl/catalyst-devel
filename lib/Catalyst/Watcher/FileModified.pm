package Catalyst::Watcher::FileModified;

use Moose;

use File::Find;
use File::Modified;
use File::Spec;
use Time::HiRes qw/sleep/;
use namespace::clean -except => 'meta';

extends 'Catalyst::Watcher';

has interval => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has _watched_files => (
    is         => 'ro',
    isa        => 'HashRef[Str]',
    lazy_build => 1,
    clearer    => '_clear_watched_files',
);

has _modified => (
    is         => 'rw',
    isa        => 'File::Modified',
    lazy_build => 1,
    clearer    => '_clear_modified',
);


sub _build__watched_files {
    my $self = shift;

    my $regex = $self->regex;

    my %list;
    finddepth(
        {
            wanted => sub {
                my $path = File::Spec->rel2abs($File::Find::name);
                return unless $path =~ /$regex/;
                return unless -f $path;

                $list{$path} = 1;

                # also watch the directory for changes
                my $cur_dir = File::Spec->rel2abs($File::Find::dir);
                $cur_dir =~ s{/script/..}{};
                $list{$cur_dir} = 1;
            },
            follow_fast => $self->follow_symlinks ? 1 : 0,
            no_chdir    => 1
        },
        @{ $self->directories }
    );

    return \%list;
}

sub _build__modified {
    my $self = shift;

    return File::Modified->new(
        method => 'mtime',
        files  => [ keys %{ $self->_watched_files } ],
    );
}

sub watch {
    my $self      = shift;
    my $restarter = shift;

    while (1) {
        sleep $self->interval if $self->interval > 0;

        my @changes = $self->_changed_files;

        next unless @changes;

        $restarter->handle_changes(@changes);

        last;
    }
}

sub _changed_files {
    my $self = shift;

    my @changes;

    eval {
        @changes = map { { file => $_, status => 'modified' } }
            grep { -f $_ } $self->_modified->changed;
    };

    if ($@) {
        # File::Modified will die if a file is deleted.
        die unless $@ =~ /stat '(.+)'/;

        push @changes, {
            file   => $1 || 'unknown file',
            status => 'deleted',
        };

        $self->_clear_watched_files;
        $self->_clear_modified;
    }
    else {
        $self->_modified->update;

        my $old_watch = $self->_watched_files;

        $self->_clear_watched_files;

        my $new_watch = $self->_watched_files;

        my @new_files = grep { !defined $old_watch->{$_} }
            grep {-f}
            keys %{$new_watch};

        if (@new_files) {
            $self->_clear_modified;
            push @changes, map { { file => $_, status => 'added' } } @new_files;
        }
    }

    return @changes;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Catalyst::Watcher::FileModified - Watch for changed application files using File::Modified

=head1 SYNOPSIS

    my $watcher = Catalyst::Watcher::FileModified->new(
        directories => '/path/to/MyApp',
        regex       => '\.yml$|\.yaml$|\.conf|\.pm$',
    );

    while (1) {
        my @changed_files = $watcher->watch();
        ...
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

L<Catalyst>, L<Catalyst::Watcher>, L<Catalyst::Restarter>,
<File::Modified>

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
