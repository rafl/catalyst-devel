package Catalyst::Helper::ComponentGen;
use Moose;
use namespace::autoclean;
extends { 'Catalyst::Helper' };

# Test
$self->{test_dir} = File::Spec->catdir( $FindBin::Bin, '..', 't' );
$self->{test}     = $self->next_test;

# Helper
if ($helper) {
    my $comp  = $self->{long_type};
    my $class = "Catalyst::Helper::$comp\::$helper";
    eval "require $class";

    if ($@) {
        Catalyst::Exception->throw(
            message => qq/Couldn't load helper "$class", "$@"/ );
    }

    ## NO TOUCHY
    if ( $class->can('mk_compclass') ) {
        return 1 unless $class->mk_compclass( $self, @args );
    }
    else { return 1 unless $self->_mk_compclass }

    if ( $class->can('mk_comptest') ) {
        $class->mk_comptest( $self, @args );
    }
    else { $self->_mk_comptest }
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
