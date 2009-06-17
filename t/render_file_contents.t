use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Catalyst::Helper;
use MyTestHelper;

use Test::More tests => 1;

my $helper = bless {}, 'MyTestHelper';

package MyTestHelper;
use Test::More;
use File::Temp qw/tempfile/;

my ($fh, $fn) = tempfile;
close $fh;

ok( $helper->render_file_contents('example1',  $fn, { test_var => 'test_val' }), "file contents rendered" ); 
