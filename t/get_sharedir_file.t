use strict;
use warnings;

use Test::MockObject::Extends;
use Test::More tests => 3;
use Test::Exception;

use Catalyst::Helper;

my $i = Test::MockObject::Extends->new('Catalyst::Helper');

throws_ok {
    $i->get_sharedir_file(qw/does not exist and hopefully never will or we are
        totally screwed.txt/);
} qr/Cannot find/, 'Exception for file not found from ->get_sharedir_file';

lives_ok {
    ok($i->get_sharedir_file('Makefile.PL.tt'), 'has contents');
} 'Can get_sharedir_file';

