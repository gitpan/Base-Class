
use strict;
use warnings;

use Test::More qw( no_plan );
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' );
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use baseBase;
use_ok( 'baseBase' );
use_ok( 'Base::Class' );

my $foo = eval{ Foo->new(); };
ok( $foo && ! $@, 'Foo was made without error' );
ok( $foo->get_did_init() eq 'true', 'Init value set to object successfully' );

package Foo;

use strict;
use warnings;

use base qw( Base::Class );

sub _init {
	my ( $self ) = @_;

	$self = $self->SUPER::_init();
	$self->set_did_init( 'true' );

	return $self;
}
