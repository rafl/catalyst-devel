use strict;
use warnings;

use FindBin qw/$Bin/;

use Test::More tests => 3;

my $cat = `which catalyst.pl`;
chomp($cat);
is system("rm -rf $Bin/../TestAppForComparison"), 0 or BAIL_OUT;
is system("cd $Bin/../; $^X -I $Bin/../lib $cat TestAppForComparison"), 0 or BAIL_OUT;
my $diff = `diff -urN -x .svn -x Changes $Bin/TestAppForComparison $Bin/../TestAppForComparison`;
ok !length($diff), 'Generated same TestApp',
    or warn($diff);

