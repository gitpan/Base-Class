
use strict;
use warnings;

use Test::More qw( no_plan );
use Data::Dumper;
# use lib ( '../lib', 'lib', 'tlib', 't/tlib' ); 
# use lib ( '../lib', 'lib' );
use lib ( 't/' );

use_ok( 'Base::Class' );
use_ok( 'Data::Dumper' );

my $base = eval{ Base::Class->new(); };
ok( $base && ! $@, 'Able to get a new Base object' );

my $as_hash = {
	'one' => 1,
	1     => 'one',
	'arr' => [ qw( one two three ) ],
	'hsh' => { 'key' => { 'key2' => 'value' } },
};
$base->seed( $as_hash, 0 );
can_ok( $base, map{ "get_${_}" } keys %$as_hash );

my $err = 0;
open STDERR, '>> stderr' or $err++;
ok( ! $err, 'Redirect of STDERR Seems to be fine' );
ok( ! $@ , 'Nearly certain there was no error infact' );
ok( -r 'stderr', 'OK, I see the file; we are good' );

eval{ $base->dump(); };
ok( ! $@, 'Dumped to STDERR without error' );
close STDERR;

open my $file, 'stderr' or $err++;
ok( ! $@ && ! $err, 'No error when opening STDERR output for input' );
my $eval_block = join( '', <$file> );
close $file;
$eval_block =~ s/\$Base\s+=\s+//g;

my $new_struct = eval( $eval_block );
ok( ! $@, 'No error when evaling dumped block' );
ok( ref( $new_struct ) eq ref( $as_hash ), 'Reference types are the same' );
is_deeply( $base->hashify(), $as_hash, 'Base->hashify() is $as_hash' );
is_deeply( $new_struct, $as_hash, '$new_struct is $as_hash' );

unlink( 'stderr' );
ok( ! -r 'stderr', 'Cannot find the output file anymore.. yay!' );
