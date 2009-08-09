# t0m++
package My::Types;
use MooseX::Types -declare [qw/ ValidAppName ValidAppComponent /];

my $appname_re = qr/[\w:]+/;
my $regex = qr/$appname_re::(M|V|C|Model|View|Controller)::.*/;

subtype ValidAppName, 
   as Str,
   where { /^$appname_re$/ && ! /$regex/ };

subtype ValidAppComponent,
   as Str,
   where { /^$regex$/ };

subtype AppEnv,
   as Str,
   where { /\w/ };
   
coerce ValidAppName,
   from ValidAppComponent,
   via { Catalyst::Utils::class2appclass($_); };
   
coerce 'ValidAppEnv',
   from Str,
   via { Catalyst::Utils::class2env($_); };

coerce AppEnv,
   from Str,
   via { Catalyst::Utils::class2env($_) };

package main;
use Test::More 'no_plan';
use Moose::Util::TypeContraints;
use My::Types qw/ValidAppName ValidAppComponent AppEnv/;

my $app_tc = find_type_constraint(ValidAppName);
ok $app_tc;
ok !$app_tc->check('');
ok $app_tc->check('MyApp');

my $comp_tc = find_type_constraint(ValidAppComponent);
ok $comp_tc;
ok !$comp_tc->check('');
ok !$comp_tc->check('MyApp');
ok $comp_tc->check('MyApp::Model::Foo');

my $env_tc = my $comp_tc = find_type_constraint(AppEnv);
ok $env_tc;
#ok !$env_tc->check('');
#ok !$env_tc->check('
is $app_tc->coerce('MyApp::Model::Foo'), 'MyApp';

done_testing;

