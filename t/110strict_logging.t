
use strict;
use warnings;

use Test::More qw( no_plan );

use lib ( 't/' );

use Base::Class qw( logger );
use_ok( 'Base::Class' );

{
	no strict 'refs';
	*loggit = sub { return Base::Class::logger( @_ ); };
}

my $base = eval{ Base::Class->new(); }; 
ok( $base && ! $@, 'Instantiation of Base was just fine' );

my $err;
open STDERR, '>> stderr' or $err++;
ok( ! $err, 'Able to redirect STDERR to local file' );
ok( -r 'stderr', 'Able to locate redirection of STDERR' );

eval{ $base->logger( 'test1' ); };
ok( ! $@, 'Able to call logger via object without fail' );

$Base::Class::STRICT_LOGGING = 0;
eval{ logger( 'test2', Base::Class::TRACE ); };
ok( ! $@, 'Able to call logger via exporter without fail' );

eval{ logger( 'test2', Base::Class::CRITICAL ); };
ok( ! $@, 'Able to call logger via exporter without fail' );

$Base::Class::STRICT_LOGGING = 1;
eval{ loggit( 'test3' ); };
ok( ! $@, 'Able to call logger via glob without fail' );

close STDERR;

open my $stderr, 'stderr' or $err++;
ok( ! $err, 'Able to open stderr file handle for input' );
my @file = <$stderr>;
close $stderr;

ok( @file && scalar( @file ) == 3, 'Retrieved input data, matches as expected' );
ok( $file[0] =~ /test1$/s, 'First line matches' );
ok( $file[1] =~ /test2\s\d+$/s, 'Second line matches' );
ok( $file[2] =~ /test3$/s, 'Third line matches' );

unlink 'stderr';
ok( ! -r 'stderr', 'STDERR redirect file can no longer be found' );
