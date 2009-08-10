package Catalyst::Helper::AppGen;

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use MooseX::Types -declare [qw/ ValidAppName ValidAppComponent Dir AppEnv/];
use namespace::autoclean;

extends { 'Catalyst::Helper' };

my $appname_re = qr/[\w:]+/;
my $regex = qr/$appname_re::(M|V|C|Model|View|Controller)::.*/;

subtype ValidAppName, 
   as Str,
   where { /^$appname_re$/ && ! /$regex/ };

subtype ValidAppComponent,
   as Str,
   where { /^$regex$/ };
   
subtype Dir,
   as Str,
   where { s/\:\:/-/g };

subtype AppEnv,
   as Str,
   where { /\w/ };
   
coerce ValidAppName,
   from ValidAppComponent,
   via { Catalyst::Utils::class2appclass($_); },

coerce AppEnv,
   from Str,
   via { Catalyst::Utils::class2env($_) };   

has name => ( 
    is => 'ro', 
    isa => ValidAppName,
    traits => [qw(Getopt)],
    cmd_aliases => 'n',
);

has dir  => ( 
    is => 'ro', 
    isa => Dir,
    traits => [qw(Getopt)],
    cmd_aliases => 'dir', 

); 

has script  => ( 
    is => 'ro', 
    isa => Str,
    traits => [qw(NoGetopt)],
);

has app_prefix => (
    is => 'ro',
    isa => Str,
    traits => [qw(NoGetopt)],
);

has app_env => (
    is => 'ro',
    isa => ValidAppEnv,
    traits => [qw(NoGetopt)],
);



sub mk_app {
    my ( $self, $name ) = @_;

    # Needs to be here for PAR
    require Catalyst;

    if ( $name =~ /[^\w:]/ || $name =~ /^\d/ || $name =~ /\b:\b|:{3,}/) {
        warn "Error: Invalid application name.\n";
        return 0;
    }
    $self->{name            } = $name;
    $self->{dir             } = $name;
    $self->{dir             } =~ s/\:\:/-/g;
    $self->{script          } = File::Spec->catdir( $self->{dir}, 'script' );
    $self->{appprefix       } = Catalyst::Utils::appprefix($name);
    $self->{appenv          } = Catalyst::Utils::class2env($name);
    $self->{startperl       } = -r '/usr/bin/env'
                                ? '#!/usr/bin/env perl'
                                : "#!$Config{perlpath} -w";
    $self->{scriptgen       } = $Catalyst::Devel::CATALYST_SCRIPT_GEN || 4;
    $self->{catalyst_version} = $Catalyst::VERSION;
    $self->{author          } = $self->{author} = $ENV{'AUTHOR'}
      || eval { @{ [ getpwuid($<) ] }[6] }
      || 'Catalyst developer';

    my $gen_scripts  = ( $self->{makefile} ) ? 0 : 1;
    my $gen_makefile = ( $self->{scripts} )  ? 0 : 1;
    my $gen_app = ( $self->{scripts} || $self->{makefile} ) ? 0 : 1;

    if ($gen_app) {
        $self->_mk_dirs;
        $self->_mk_config;
        $self->_mk_appclass;
        $self->_mk_rootclass;
        $self->_mk_readme;
        $self->_mk_changes;
        $self->_mk_apptest;
        $self->_mk_images;
        $self->_mk_favicon;
    }
    if ($gen_makefile) {
        $self->_mk_makefile;
    }
    if ($gen_scripts) {
        $self->_mk_cgi;
        $self->_mk_fastcgi;
        $self->_mk_server;
        $self->_mk_test;
        $self->_mk_create;
        $self->_mk_information;
    }
    return $self->{dir};
}



1;
