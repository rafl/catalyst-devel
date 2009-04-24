package Catalyst::Watcher;

use Moose;
use Moose::Util::TypeConstraints;

use File::Find;
use File::Modified;
use File::Spec;
use Time::HiRes qw/sleep/;
use namespace::clean -except => 'meta';

has interval => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has regex => (
    is      => 'ro',
    isa     => 'RegexpRef',
    default => sub { qr/(?:\/|^)(?!\.\#).+(?:\.yml$|\.yaml$|\.conf|\.pm)$/ },
);

my $dir = subtype
       as 'Str'
    => where { -d $_ }
    => message { "$_ is not a valid directory" };

my $array_of_dirs = subtype
       as 'ArrayRef[Str]',
    => where { map { -d } @{$_} }
    => message { "@{$_} is not a list of valid directories" };

coerce $array_of_dirs
    => from $dir
    => via { [ $_ ] };

has directory => (
    is      => 'ro',
    isa     => $array_of_dirs,
    default => sub { [ File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, '..' ) ) ] },
    coerce  => 1,
);

has follow_symlinks => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
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
);

sub _build__watched_files {
    my $self = shift;

    my $regex = $self->regex;

    my %list;
    finddepth(
        {
            wanted => sub {
                my $file = File::Spec->rel2abs($File::Find::name);
                return unless $file =~ /$regex/;
                return unless -f $file;

                $list{$file} = 1;

                # also watch the directory for changes
                my $cur_dir = File::Spec->rel2abs($File::Find::dir);
                $cur_dir =~ s{/script/..}{};
                $list{$cur_dir} = 1;
            },
            follow_fast => $self->follow_symlinks ? 1 : 0,
            no_chdir    => 1
        },
        @{ $self->directory }
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

sub find_changed_files {
    my $self = shift;

    my @changes;
    my @changed_files;

    sleep $self->interval if $self->interval > 0;

    eval { @changes = $self->_modified->changed };
    if ($@) {
        # File::Modified will die if a file is deleted.
        my ($deleted_file) = $@ =~ /stat '(.+)'/;
        push @changed_files,
            {
            file => $deleted_file || 'unknown file',
            status => 'deleted',
            };
    }

    if (@changes) {
        $self->_modified->update;

        @changed_files = map { { file => $_, status => 'modified' } }
            grep { -f $_ } @changes;

        # We also need to check to see if a new directory was created
        unless (@changed_files) {
            my $old_watch = $self->_watched_files;

            $self->_clear_watched_files;

            my $new_watch = $self->_watched_files;

            @changed_files
                = map { { file => $_, status => 'added' } }
                grep { !defined $old_watch->{$_} }
                keys %{$new_watch};

            return unless @changed_files;
        }
    }

    return @changed_files;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Catalyst::Watcher - Watch for changed application files

=head1 SYNOPSIS

    my $watcher = Catalyst::Engine::HTTP::Restarter::Watcher->new(
        directory => '/path/to/MyApp',
        regex     => '\.yml$|\.yaml$|\.conf|\.pm$',
        delay     => 1,
    );
    
    while (1) {
        my @changed_files = $watcher->watch();
    }

=head1 DESCRIPTION

This class monitors a directory of files for changes made to any file
matching a regular expression.  It correctly handles new files added to the
application as well as files that are deleted.

=head1 METHODS

=head2 new ( directory => $path [, regex => $regex, delay => $delay ] )

Creates a new Watcher object.

=head2 watch

Returns a list of files that have been added, deleted, or changed since the
last time watch was called.

=head2 DETECT_PACKAGE_COMPILATION

Returns true if L<B::Hooks::OP::Check::StashChange> is installed and
can be used to detect when files are compiled. This is used internally
to make the L<Moose> metaclass of any class being reloaded immutable.

If L<B::Hooks::OP::Check::StashChange> is not installed, then the
restarter makes all application components immutable. This covers the
simple case, but is less useful if you're using Moose in components
outside Catalyst's namespaces, but inside your application directory.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Engine::HTTP::Restarter>, L<File::Modified>

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 THANKS

Many parts are ripped out of C<HTTP::Server::Simple> by Jesse Vincent.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
