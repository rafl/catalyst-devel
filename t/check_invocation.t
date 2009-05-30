use strict;
use warnings;

use FindBin qw/$Bin/;
use Test::More test => 1;

use lib "$Bin/../lib";

use Catalyst::Helper;

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
