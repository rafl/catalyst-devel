use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Catalyst::Helper;

use Test::More;

my $helper = bless {}, 'Catalyst::Helper';

use File::Temp qw/tempfile/;

my ($fh, $fn) = tempfile;
close $fh;

ok( $helper->render_file_contents('example1',  $fn, { test_var => 'test_val' }), "file contents rendered" ); 
ok -r $fn;
ok -s $fn;
unlink $fn;

done_testing;
