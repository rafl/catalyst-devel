use strict;
use warnings;

use Test::More;
use Test::Exception;

use Catalyst::Helper;

my $i = bless {}, 'Catalyst::Helper';

throws_ok {
    $i->get_sharedir_file(qw/does not exist and hopefully never will or we are
        totally screwed.txt/);
} qr/Cannot find/, 'Exception for file not found from ->get_sharedir_file';

lives_ok {
    ok($i->get_sharedir_file('Makefile.PL.tt'), 'has contents');
} 'Can get_sharedir_file';

done_testing;
