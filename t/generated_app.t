use strict;
use warnings;
use lib ();
use File::Temp qw/ tempdir tmpnam /;
use File::Spec;
use Catalyst::Devel;

my $dir = tempdir(CLEANUP => 1);
my $devnull = File::Spec->devnull;

use Test::More;

diag "Generated app is in $dir";

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

chdir(File::Spec->catdir($dir, 'TestApp'));
lib->import(File::Spec->catdir($dir, 'TestApp', 'lib'));

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
    if ($fn =~ /\.p[ml]/) {
        is system($^X, '-c', $fn), 0, "$fn compiles";
    }
}

is system($^X, 'Makefile.PL'), 0, 'Ran Makefile.PL';
ok -e "Makefile", "Makefile generated";
is system("make"), 0, 'Run make';

{
    local $ENV{TEST_POD} = 1;
    local $ENV{CATALYST_DEBUG} = 0;
    foreach my $test (grep { m|^t/| } @files) {
        subtest "Generated app test: $test", sub {
            require $test;
        }
    }
}

my $server_script = do {
    open(my $fh, '<', File::Spec->catdir(qw/script testapp_server.pl/)) or fail $!;
    local $/;
    <$fh>;
};

ok $server_script;
ok $server_script =~ qr/CATALYST_SCRIPT_GEN}\s+=\s+(\d+)/,
    'SCRIPT_GEN found in generated output';
is $1, $Catalyst::Devel::CATALYST_SCRIPT_GEN, 'Script gen correct';

chdir('/');
done_testing;
