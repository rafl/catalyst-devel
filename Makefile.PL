use inc::Module::Install 0.62;

perl_version '5.8.1';

name 'Catalyst-Devel';
all_from 'lib/Catalyst/Devel.pm';

requires 'perl'        => '5.8.1';
requires 'Class::Accessor::Fast';
requires 'Path::Class' => '0.09';
requires 'Template'    => '2.14';
requires 'Catalyst'    => '5.66';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'YAML'        => '0.55';
requires 'Module::Install' => '0.62';
requires 'File::Copy::Recursive';

WriteAll;
