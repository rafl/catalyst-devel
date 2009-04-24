use inc::Module::Install 0.64;

name     'Catalyst-Devel';
all_from 'lib/Catalyst/Devel.pm';

requires 'Catalyst'    => '5.7000';
requires 'Catalyst::Action::RenderView' => '0.04';
requires 'Catalyst::Plugin::Static::Simple' => '0.16';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Class::Accessor::Fast';
requires 'Config::General'; # as of 1.07, we use .conf and not .yaml
requires 'File::Copy::Recursive';
requires 'Module::Install' => '0.64';
requires 'parent'; # as of 1.04
requires 'Path::Class' => '0.09';
requires 'Template'    => '2.14';

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

auto_install;

WriteAll;
