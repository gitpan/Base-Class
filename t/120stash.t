
use strict;
use warnings;

use lib ( 't/' );

use Test::More qw( no_plan );
use baseBase;
use notabase;
use isabasebase;
use_ok( 'Base::Class' );

my $base_base = eval{ baseBase->new(); };
ok( ! $@ );
my $sub_bb    = eval{ isabasebase->new(); };
ok( ! $@ );
my $notabase  = eval{ notabase->new(); };
ok( ! $@ );
my $base      = eval{ Base::Class->new(); };
ok( ! $@ );

isa_ok( $base_base, 'baseBase' );
isa_ok( $base_base, 'Base::Class' );
isa_ok( $sub_bb, 'baseBase' );
isa_ok( $sub_bb, 'Base::Class' );
isa_ok( $sub_bb, 'isabasebase' );
ok( ! ( $notabase->isa( 'Base::Class' ) ) );

$sub_bb->set_one( 1 );
ok( $sub_bb->get_one() == 1 );
ok( ! $base_base->can( 'get_one' ) );
ok( ! $base->can( 'get_one' ) );
ok( ! $notabase->can( 'get_one' ) );

$base_base->set_two( 2 );
ok( $base_base->can( 'get_two' ) );
ok( $base_base->get_two() == 2 );
ok( $sub_bb->can( 'get_two' ) );
ok( ( $sub_bb->get_two() || 0 ) != 2 );
ok( ! $base->can( 'get_two' ) );
ok( ! $notabase->can( 'get_two' ) );

$base->set_three( 3 );
ok( $base_base->can( 'get_three' ) );
ok( ( $base_base->get_three() || 0 ) != 3 );
ok( $sub_bb->can( 'get_three' ) );
ok( ( $sub_bb->get_three() || 0 ) != 3 );
ok( $base->can( 'get_three' ) );
ok( $base->get_three() == 3 );
ok( ! $notabase->can( 'get_three' ) );
