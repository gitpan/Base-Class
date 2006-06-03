
use strict;
use warnings;

use Test::More qw( no_plan );
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' ); 
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use_ok( 'Base::Class' );

use Base::Class;

eval{ use Storable; };
exit if ( $@ );

$Base::Class::CLONE = 'Storable';
$Base::Class::CLONE_SUB = 'dclone';

my $o = Base::Class->new();
my $c = $o->copy();
