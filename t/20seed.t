
use strict;
use warnings;

use Test::More qw( no_plan );
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' );
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use_ok( 'baseBase' );
use_ok( 'Base::Class' );

my $seed = {
	'one' => 1,
	'two' => 2,
	'three' => 3,
	'four' => 4,
	'five' => { 'hash' => 1 }, # Test reference
};

my $base = eval{ baseBase->new(); };
ok( $base && ! $@, 'Gotta new base object, will attempt to seed object' );

eval{ $base->seed( $seed, 0 ); };
ok( ! $@, 'Did not catch an error when seeding' );

for ( keys %$seed ) {
	my $m = "get_${_}";
	ok( $base->can( $m ), "Object hasa $m method" );
	ok( $base->$m() == $seed->{$_}, 'Base and seed hash match one another' );

	my ( $s, $o ) = ( $seed->{$_}, $base->$m() );
	ok( "$s" eq "$o", 'References appear to be the same as well' );
}

$base = eval{ baseBase->new; };
ok( ! $@ && $base, 'Cleared out old base, new one instantiated without error' );

eval{ $base->seed( $seed, 1 ); };
ok( ! $@ && $base, 'Seeded object with private methods without problem' );

for ( keys %$seed ) {
	my $m = "_get_${_}";
	ok( $base->can( $m ), 'Base hasa seeded method' );

	eval{ $base->$m(); };
	eval( $@ && "$@" =~ /private.*method/s, 'Cannot access private method as expected' );
}


