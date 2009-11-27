use strict;
use warnings;

use File::Temp qw/ tempdir tmpnam /;
use File::Spec;
use Test::WWW::Mechanize;
use Catalyst::Devel;

my $dir = tempdir();
my $devnull = File::Spec->devnull;

use Test::More;

diag "In $dir";

{
    my $exit;
    if ($^O eq 'MSWin32') {
      $exit = system("cd $dir & catalyst TestApp > $devnull 2>&1");
    }
    else {
      $exit = system("cd $dir; catalyst.pl TestApp > $devnull 2>&1");
    }
    is $exit, 0, 'Exit status ok';
}
# FIXME paths / nl work on win32
chdir("$dir/TestApp/");

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

foreach my $fn (@files) {
    ok -r $fn, "Have $fn in generated app";
    if ($fn =~ /script/) {
        ok -x $fn, "$fn is executable";
    }
}

## Makefile stuff
my $makefile_status = `$^X Makefile.PL`;
ok $makefile_status, "Makefile ran okay";
ok -e "Makefile", "Makefile exists";

is system("make"), 0, 'Run make';

{
    local $ENV{TEST_POD} = 1;

    foreach my $test (grep { m|^t/| } @files) {
        subtest "Generated app test: $test", sub {
            require $test;
        }
    }
}

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

my $server_script = do {
    open(my $fh, '<', 'script/testapp_server.pl') or die $!;
    local $/;
    <$fh>;
};

ok $server_script =~ qr/CATALYST_SCRIPT_GEN}\s+=\s+(\d+)/,
    'SCRIPT_GEN found in generated output';
is $1, $Catalyst::Devel::CATALYST_SCRIPT_GEN, 'Script gen correct';

chdir('/');

done_testing;

