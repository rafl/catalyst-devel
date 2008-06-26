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

auto_install;

WriteAll;
