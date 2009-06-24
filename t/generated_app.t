use strict;
use warnings;

use File::Temp qw/ tempdir tmpnam /;
use File::Spec;
use Test::WWW::Mechanize;

my $dir = tempdir(); # CLEANUP => 1 );
my $devnull = File::Spec->devnull;

use Test::More;
{
    # Check exit status here
    if ($^O eq 'MSWin32') {
      system("cd $dir & catalyst TestApp > $devnull 2>&1");
    }
    else {
      system("cd $dir; catalyst.pl TestApp > $devnull 2>&1");
    }
}
# Fix paths / nl work on win32
chdir("$dir/TestApp/");
warn($dir);

# Ok, this is lame.. Also, check +x permissions?
my @files = qw|
    Makefile.PL
    testapp.conf
lib/TestApp.pm
lib/TestApp/Controller/Root.pm
README
Changes
t/01app.t
t/02pod.t
t/03podcoverage.t
root/static/images/catalyst_logo.png
root/static/images/btn_120x50_built.png
root/static/images/btn_120x50_built_shadow.png
root/static/images/btn_120x50_powered.png
root/static/images/btn_120x50_powered_shadow.png
root/static/images/btn_88x31_built.png
root/static/images/btn_88x31_built_shadow.png
root/static/images/btn_88x31_powered.png
root/static/images/btn_88x31_powered_shadow.png
root/favicon.ico
Makefile.PL
script/testapp_cgi.pl
script/testapp_fastcgi.pl
script/testapp_server.pl
script/testapp_test.pl
script/testapp_create.pl
|;

plan 'tests' => scalar @files + 4;

foreach my $fn (@files) {
    ok -r $fn, "Have $fn in generated app";
}

## Makefile stuff
my $makefile_status = `$^X Makefile.PL`;
ok $makefile_status, "Makefile ran okay";
ok -e "Makefile", "Makefile exists";
my $newapp_test_status = `prove -l t/ 2> $devnull`;
ok $newapp_test_status, "Tests ran okay";
#is $newapp_test_status, ;

## Moosey server tests - kmx++
my $server_path   = File::Spec->catfile('script', 'testapp_server.pl');
my $port = int(rand(10000)) + 40000; # get random port between 40000-50000

my $childpid = fork();
die "fork() error, cannot continue" unless defined($childpid);

if ($childpid == 0) {
  system("$^X $server_path -p $port > $devnull 2>&1");
  exit; # just for sure; we should never got here
}

sleep 10; #wait for catalyst application to start
my $mech = Test::WWW::Mechanize->new;
$mech->get_ok( "http://localhost:" . $port );

kill 'KILL', $childpid;


