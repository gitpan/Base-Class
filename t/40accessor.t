
use strict;
use warnings;

use Test::More qw( no_plan );
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' );
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use baseBase;
use_ok( 'baseBase' );
use_ok( 'Base::Class' );

my $stuff = {
	'one' => 1,
	'two' => 2,
	'three' => [ qw( one two three ) ],
	'four' => { 'key' => 'value' },
};

my $base = eval{ baseBase->new(); };
ok( ! $@ && $base, 'Able to get new base object' );
my $foo  = eval{ Foo->new();      };
ok( ! $@ && $foo, 'Able to get new sub-base object' );

for ( keys %$stuff ) {
	my $m = "set_${_}";
	my $g = "get_${_}";
	eval{ $base->$m( $stuff->{$_} ); };
	ok( ! $@, 'Nothing bad happened to the base object while setting' );
	my $s = eval{ $base->$g() };
	ok( ! $@, 'Did not have a fit when extracting data from object' );
	ok( "$s" eq "$stuff->{$_}", 'The stringified values of stuff and getter are equal' );
}

$base = eval{ baseBase->new(); };
ok( $base && ! $@, 'Able to gain a new base object' );

for ( keys %$stuff ) {
	my $s = "_set_${_}";
	my $g = "_get_${_}";
	eval{ $base->$s( $stuff->{$_} ) };
	ok( ! $@, 'Able to dump stuff into new object' );
	eval{ $base->$g; };
	ok( $@, 'Died when trying to get the stuff back' );
	my $r = eval{ $foo->hit_accessor( $base, $g ); };
	ok( ! $@, 'Able to get the data from within a base-class of base' );
	ok( "$r" eq "$stuff->{$_}", 'Base extraction of private method matches reference' );
}

package Foo;

use strict;
use warnings;

use base qw( Base::Class );

sub hit_accessor {
	my ( $self, $obj, $m ) = @_;
	return $obj->$m();
}
