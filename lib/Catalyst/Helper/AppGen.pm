package Catalyst::Helper::AppGen;

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends { 'Catalyst::Helper' };

has name => ( 
    is => 'ro', 
    isa => Str,
    traits => [qw(Getopt)],
    cmd_aliases => 'n',
);

has dir  => ( 
    is => 'ro', 
    isa => Str,
    traits => [qw(Getopt)],
    cmd_aliases => 'n', 
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

sub mk_component {
    my $self = shift;
    my $app  = shift;
    $self->{app} = $app;
    $self->{author} = $self->{author} = $ENV{'AUTHOR'}
      || eval { @{ [ getpwuid($<) ] }[6] }
      || 'A clever guy';
    $self->{base} ||= File::Spec->catdir( $FindBin::Bin, '..' );
    unless ( $_[0] =~ /^(?:model|view|controller)$/i ) {
        my $helper = shift;
        my @args   = @_;
        my $class  = "Catalyst::Helper::$helper";
        eval "require $class";

        if ($@) {
            Catalyst::Exception->throw(
                message => qq/Couldn't load helper "$class", "$@"/ );
        }

        if ( $class->can('mk_stuff') ) {
            return 1 unless $class->mk_stuff( $self, @args );
        }
    }
    else {
        my $type   = shift;
        my $name   = shift || "Missing name for model/view/controller";
        my $helper = shift;
        my @args   = @_;
       return 0 if $name =~ /[^\w\:]/;
        $type              = lc $type;
        $self->{long_type} = ucfirst $type;
        $type              = 'M' if $type =~ /model/i;
        $type              = 'V' if $type =~ /view/i;
        $type              = 'C' if $type =~ /controller/i;
        my $appdir = File::Spec->catdir( split /\:\:/, $app );
        my $test_path =
          File::Spec->catdir( $FindBin::Bin, '..', 'lib', $appdir, 'C' );
        $type = $self->{long_type} unless -d $test_path;
        $self->{type}  = $type;
        $self->{name}  = $name;
        $self->{class} = "$app\::$type\::$name";

        # Class
        my $path =
          File::Spec->catdir( $FindBin::Bin, '..', 'lib', $appdir, $type );
        my $file = $name;
        if ( $name =~ /\:/ ) {
            my @path = split /\:\:/, $name;
            $file = pop @path;
            $path = File::Spec->catdir( $path, @path );
        }
        $self->mk_dir($path);
        $file = File::Spec->catfile( $path, "$file.pm" );
        $self->{file} = $file;

        # Fallback
        else {
            return 1 unless $self->_mk_compclass;
            $self->_mk_comptest;
        }
    }
    return 1;
}

1;
