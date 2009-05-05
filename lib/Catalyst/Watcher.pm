package Catalyst::Watcher;

use Moose;
use Moose::Util::TypeConstraints;

use Cwd qw( abs_path );
use File::Spec;
use FindBin;
use namespace::clean -except => 'meta';

has regex => (
    is      => 'ro',
    isa     => 'RegexpRef',
    default => sub { qr/(?:\/|^)(?!\.\#).+(?:\.yml|\.yaml|\.conf|\.pm)$/ },
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

has directories => (
    is      => 'ro',
    isa     => $array_of_dirs,
    default => sub { [ abs_path( File::Spec->catdir( $FindBin::Bin, '..' ) ) ] },
    coerce  => 1,
);

has follow_symlinks => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub instantiate_subclass {
    my $class = shift;

    if ( eval { require Catalyst::Watcher::Inotify; 1; } ) {
        return Catalyst::Watcher::Inotify->new(@_);
    }
    else {
        die $@ if $@ && $@ !~ /Can't locate/;
        require Catalyst::Watcher::FileModified;
        return Catalyst::Watcher::FileModified->new(@_);
    }
}

__PACKAGE__->meta->make_immutable;

1;
