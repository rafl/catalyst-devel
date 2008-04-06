use inc::Module::Install 0.64;

name     'Catalyst-Devel';
all_from 'lib/Catalyst/Devel.pm';

requires 'Class::Accessor::Fast';
requires 'Path::Class' => '0.09';
requires 'Template'    => '2.14';
requires 'Catalyst'    => '5.7000';
requires 'Catalyst::Action::RenderView' => '0.04';
requires 'Catalyst::Plugin::Static::Simple' => '0.16';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'parent';
requires 'YAML'        => '0.55';
requires 'Module::Install' => '0.64';
requires 'File::Copy::Recursive';

auto_install;

WriteAll;
