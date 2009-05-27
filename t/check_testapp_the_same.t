use strict;
use warnings;

use FindBin qw/$Bin/;

use Test::More tests => 3;

## find out where catalyst.pl is
my $cat = `which catalyst.pl`;
chomp($cat);

## remove any existing test apps
is system("rm -rf $Bin/../TestAppForComparison"), 0 or BAIL_OUT;

## create a new test app to compare to
is system("cd $Bin/../; $^X -I$Bin/../lib $cat TestAppForComparison"), 0 or BAIL_OUT;

SKIP: {
 
    my $diff;
    eval {
        $diff = `diff -urN -x .svn -x Changes $Bin/TestAppForComparison $Bin/../TestAppForComparison`;
    };
    
    skip "no diff program installed, skipping", 1 if $@;
    
    ok !length($diff), 'Generated same TestApp', or warn($diff);
    
}
