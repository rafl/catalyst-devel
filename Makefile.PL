use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;

name     'Catalyst-Devel';
all_from 'lib/Catalyst/Devel.pm';

requires 'Moose';
requires 'MooseX::Emulate::Class::Accessor::Fast';
requires 'File::ShareDir';
requires 'namespace::clean';
requires 'namespace::autoclean';
requires 'Catalyst'    => '5.80015';
requires 'Catalyst::Action::RenderView' => '0.10';
requires 'Catalyst::Plugin::Static::Simple' => '0.28';
requires 'Catalyst::Plugin::ConfigLoader' => '0.23';
requires 'Config::General' => '2.42'; # as of 1.07, we use .conf and not .yaml
requires 'File::ChangeNotify' => '0.07';
requires 'File::Copy::Recursive';
requires 'Module::Install' => '0.91';
requires 'Path::Class' => '0.09';
requires 'Template'    => '2.14';

author_requires 'IPC::Run3';

test_requires 'Test::More' => '0.94';

install_share 'share';

if ( $^O eq 'MSWin32' ) {
    # Proc::Background needs this on Win32 but doesn't actually
    # require it, if it's missing it just dies in the Makefile.PL.
    requires 'Win32::Process' => '0.04';
    requires 'Proc::Background';
}

if (!$ENV{CATALYST_DEVEL_NO_510_CHECK}) {
    use Symbol 'gensym';
    use IPC::Open3;
    use File::Spec;
    open NULL, '>', File::Spec->devnull;
    my $err = gensym;
    my $pid = open3(gensym, '&>NULL', $err, "$^X -It/lib -MUnknownError -e 1");

    my $unknown_error = 0;

    while (<$err>) {
        $unknown_error = 1 if /^Unknown error/;
    }

    waitpid $pid, 0;

    if ($unknown_error) {
        warn <<EOE;
############################### WARNING #################################
#                                                                       #
# You are using perl 5.10.0 with the "Unknown error" bug. This can make #
# developing Catalyst applications much more painful, as it will come   #
# up with no details every time you have a syntax error in a Controller.#
#                                                                       #
# For more information see:                                             #
#                                                                       #
#  * http://rt.perl.org/rt3/Public/Bug/Display.html?id=49472            #
#                                                                       #
# It is highly recommended that you use a different version of perl or  #
# compile a patched version for Catalyst development.                   #
#                                                                       #
# To skip this check, set the CATALYST_DEVEL_NO_510_CHECK environment   #
# variable.                                                             #
#                                                                       #
#########################################################################

EOE
        my $ans = prompt('Do you want to continue?', 'no');
        exit 0 unless $ans =~ /^y(es)?\z/i;
    }
}

# kill warning from older versions of Class::C3
if ($] >= 5.009_005 && can_use('Class::C3') && !can_use('Class::C3', 0.20)) {
    requires 'Class::C3' => '0.20';
}

auto_install;

WriteAll;

if ($Module::Install::AUTHOR) {
    Meta->{values}{resources} = [
        [ 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst' ],
        [ 'IRC'         => 'irc://irc.perl.org/#catalyst' ],
        [ 'license',    => 'http://dev.perl.org/licenses/' ],
        [ 'homepage',   => 'http://dev.catalyst.perl.org/'],
        [ 'repository', => 'git://git.shadowcat.co.uk/catagits/Catalyst-Devel.git' ],
    ];

    Meta->{values}{requires} = [ grep {
        $_->[0] ne 'Class::C3'
    } @{ Meta->{values}{requires} } ];

    Meta->write;
}
