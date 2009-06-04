use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Temp qw/tempfile/;
use lib "$Bin/lib";
use Data::Dumper;

use MyTestHelper;

use Test::More tests => 3;

my $helper = bless {}, 'MyTestHelper';

my $example1 = $helper->get_file('MyTestHelper', 'example1');
chomp $example1;

my $example2 = $helper->get_file('MyTestHelper', 'example2');
chomp $example2; 


is $example1, 'foobar[% test_var %]';
is $example2, 'bazquux';

my ($fh, $fn) = tempfile;
$helper->render_file($fn,  { test_var => 'test_val' });
seek $fh, 0, 0; # Rewind
my $contents;
{
    local $/; 
    $contents = <$fh>;
}
warn $contents;
is $contents, 'foobartest_val';
