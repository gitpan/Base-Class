
use strict;
use warnings;

use Test::More qw( no_plan );
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' );
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use_ok( 'Base::Class' );
use_ok( 'baseBase' );

my $base = eval{ baseBase->new(); };
ok( $base && ! $@, 'Base made without error' );

my $hash = { 'one' => { 'two' => { 'three' => { 'four' => 'four' } } } };
$base->seed( $hash );
my $new = $base->hashify();

is_deeply( $new, $hash, 'Seeded hash matches as hash version' );
