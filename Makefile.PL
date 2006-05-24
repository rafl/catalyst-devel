use inc::Module::Install 0.62;

perl_version '5.8.1';

name 'Catalyst::Helper';
all_from 'lib/Catalyst/Helper.pm';

requires 'perl'        => '5.8.1';
requires 'Class::Accessor::Fast';
requires 'Path::Class' => '0.09';
requires 'Template'    => '2.14';
requires 'Catalyst'    => '5.66';

WriteAll;
