
use strict;
use warnings;

use Test::More qw( no_plan );
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' ); 
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use_ok( 'Base::Class' );

use Base::Class;

my $base = eval{ Base::Class->new(); };
ok( $base && ! $@, 'Able to get a new Base::Class object' );

my $as_hash = {
	'one' => 1,
	1     => 'one',
	'arr' => [ qw( one two three ) ],
	'hsh' => { 'key' => { 'key2' => 'value' } },
};
$base->seed( $as_hash, 0 );
can_ok( $base, map{ "get_${_}" } keys %$as_hash );

my $copy = eval{ $base->copy(); };
diag( "$@" ) unless ok( $copy && ! $@, 'No error when copying' );
ok( ref( $copy ) eq ref( $base ), 'Reference types are the same' );
ok( "$copy" ne "$base", 'Copy is not the same memory location' );
is_deeply( $copy->hashify, $base->hashify, 'Base hashified structures are similar' );


