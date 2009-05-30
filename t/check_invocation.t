use strict;
use warnings;

use FindBin qw/$Bin/;
use Test::More tests => 1;

use lib "$Bin/../lib";

use Catalyst::Helper;

my $force    = 0;
my $help     = 0;
my $makefile = 0;
my $scripts  = 0;
my $short    = 0;

my $helper = Catalyst::Helper->new(
    {
        '.newfiles' => !$force,
        'makefile'  => $makefile,
        'scripts'   => $scripts,
        'short'     => $short,
    }
);

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass.tt', $file );
}

ok( $helper->mk_app("TestAppForInvocation"), "app invocation still works");
