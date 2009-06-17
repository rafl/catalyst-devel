use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Catalyst::Helper;
use MyTestHelper;

use Test::More tests => 1;

my $helper = bless {}, 'MyTestHelper';

package MyTestHelper;
use FindBin qw/$Bin/;
use Test::More;
use File::Temp qw/tempfile/;

my ($fh, $fn) = tempfile;
close $fh;

ok( $helper->render_sharedir_file('script/myapp_cgi.pl.tt',  { appprefix  => 'fnargh' }), "sharedir file rendered" ); 
