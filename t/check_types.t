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

coerce ValidAppName,
   from ValidAppComponent,
   via { Catalyst::Utils::class2appclass($_); };

package main;
use Test::More 'no_plan';
use Moose::Util::TypeContraints;
use My::Types qw/ValidAppName ValidAppComponent/;

my $app_tc = find_type_constraint(ValidAppName);
ok $app_tc;
ok !$app_tc->check('');
ok $app_tc->check('MyApp');

my $comp_tc = find_type_constraint(ValidAppComponent);
ok $comp_tc;
ok !$comp_tc->check('');
ok !$comp_tc->check('MyApp');
ok $comp_tc->check('MyApp::Model::Foo');

is $app_tc->coerce('MyApp::Model::Foo'), 'MyApp';

done_testing;

