
use strict;
use warnings;

use Test::More qw( no_plan );
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' );
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use ISABase;
use baseBase;

use_ok( 'Base::Class' );
use_ok( 'ISABase' );
use_ok( 'baseBase' );

my $isa = eval{ ISABase->new(); };
ok( ! $@ && $isa, 'Able to generate a Base object using @ISA' );

my $base = eval{ baseBase->new(); };
ok( ! $@ && $base, 'Able to generate a Base object using base' );

ok( UNIVERSAL::isa( $isa, 'Base::Class' ), 'Base using @ISA isa Base' );
ok( UNIVERSAL::isa( $base, 'Base::Class' ), 'Base using base isa Base' );
