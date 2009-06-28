use strict;
use warnings;

use File::Temp qw/ tempdir /;

my $dir = tempdir(); # CLEANUP => 1 );

use Test::More;
{
    # Check exit status here
    system("cd $dir; catalyst.pl TestApp");
}
# Fix paths / nl work on win32
chdir("$dir/TestApp/");

# Ok, this is lame.. Also, check +x permissions?
my @files = qw|
    Makefile.PL
    lib/TestApp.pm
|;

plan 'tests' => scalar @files;

foreach my $fn (@files) {
    ok -r $fn, "Have $fn in generated app";
}

