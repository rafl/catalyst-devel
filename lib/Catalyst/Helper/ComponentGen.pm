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

    if ( $class->can('mk_compclass') ) {
        return 1 unless $class->mk_compclass( $self, @args );
    }
    else { return 1 unless $self->_mk_compclass }

    if ( $class->can('mk_comptest') ) {
        $class->mk_comptest( $self, @args );
    }
    else { $self->_mk_comptest }
}

1;
