package Base::Class; 

use 5.006001; # 5.6.1
use strict;
use warnings;

use constant NO_LOG    => 0b00000; # 0
use constant DEBUG     => 0b00001; # 1
use constant TRACE     => 0b00010; # 2
use constant WARNING   => 0b00100; # 4
use constant ERROR     => 0b01000; # 8
use constant CRITICAL  => 0b10000; # 16

use vars qw( $AUTOLOAD $CLONE $CLONE_SUB $VERSION $STRICT_LOGGING @ISA );
$VERSION        = '0.12';
$CLONE          = 'Base::Class::clone';
$CLONE_SUB      = 'clone';
$STRICT_LOGGING = 1;

# Either modify the environment or hard-code the default here
BEGIN { $ENV{'LOG_LEVEL'} ||= ERROR | CRITICAL; }

# POSIX Should be in the Standard 5.x-ish install of Perl, however
# we may as well double check for this since I don't want to see
# someone using this as a base class and, for what ever reason,
# don't want/have POSIX installed.
eval{ use POSIX; };
{
	no strict 'refs';
	*__ftime = ( $@ ) ? sub{ join( 'X', scalar( @_ ) ) } : sub{ POSIX::strftime( @_ ) };
}

# Similar to POSIX, I don't want Exporter to be dependancy either, although
# if they have Exporter, then they will also have to have base
eval{ use base qw( Exporter ); }; 
our @EXPORT = qw( logger ) unless( $@ );

use constant LOG_LEVEL => $ENV{'LOG_LEVEL'};

{
	my $o = 0;
	sub new {
		logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
		my $self = bless( \$o++, shift );

		# This has to be snuck in here; if the clonify packages
		# are redefined, we'll already have compiled past being
		# able to re-define them.  Though, we'll only do it once
		unless( $self->can( '__clone' ) ) {
			logger( 'Inviting new clone module to come and play' ) if ( LOG_LEVEL & TRACE );
			eval( "use $CLONE;" );
			{
				no strict 'refs';
				*__clone = \&{ join( '::', $CLONE, $CLONE_SUB ) };
			}
		}
		
		return $self->_init( @_ );
	}

	sub DESTROY {
		logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
		$o--;
		return;
	}
}

sub _init {
	logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
	$_[0]
}

sub logger {
	return if ( ! $STRICT_LOGGING && $_[-1] =~ /^\d+$/s && ! ( $_[-1] & LOG_LEVEL ) );
	shift( @_ ) if ( ref( $_[0] ) ); # Ditch the object of object call
	my ( $ns, $file, $line, $routine ) = ( caller( 1 ), '0x0', $0, -1, 'main' )[ 0 .. 3 ];
	warn sprintf(
		"[%s]\t%-s%-05d%-s\n",
		__ftime( "%Y-%m-%d %H:%M:%S", localtime() ),
		"${file}::${routine}", $line,
		join( ' ', @_ )
	);
}

sub seed {
	logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
	my ( $self, $accessor_data, $private ) = @_;

	$private = ( $private ) ? '_' : '';
	for ( keys %$accessor_data ) {
		my $m = "${private}set_${_}";
		$self->$m( $accessor_data->{$_} );
	}

	return;
}

{
	my %accessors = ();
	sub dump {
		logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
		my ( $self ) = @_;

		# Again, we don't want to have to create a dependancy on Data:Dumper if
		# we really, really don't have to
		eval{ require Data::Dumper; };
		warn ( ( $@ ) ? "$self" : Data::Dumper->Dump( [ $self->hashify() ], [ ref( $self ) ] ) );
		return;
	}

	sub copy {
		logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
		my ( $self ) = @_;

		my ( $hashie, $newbie ) = ( $self->hashify(), {} );

		$newbie->{$_} = ( UNIVERSAL::isa( $hashie->{$_}, 'Base::Class' ) )
			? $hashie->{$_}->hashify()
			: __clone( $hashie->{$_} ) for ( keys %$hashie );

		my $class = ref( $self );
		my $obj   = $class->new();
		$obj->seed( $newbie );

		return $obj;
	}

	sub hashify {
		logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
		my ( $self ) = @_;
		return $accessors{"$self"};
	}
	
	sub AUTOLOAD {
		logger( 'trace', 'enter', $AUTOLOAD ) if ( LOG_LEVEL & TRACE );
		no strict 'refs';

		# Let's see if we are using a getter or a setter
		# if we are NOT, then we shouldn't be in the AUTOLOADER
		my ( $class, $p, $action, $method ) = $AUTOLOAD =~ /^(.+)::(_)?([gs]et)_(\w+)$/s;
		die( "Attempted use of undefined sub routine [$AUTOLOAD]" ) unless( $method && $action );
		$p ||= '';
		
		# Get me
		my $self = shift();

		# Now, to avoid the overhead of AUTOLOAD for the next time the accessor(s)
		# are called, we'll simply attach the method to the class.
		*{ "${class}::${p}set_${method}" } = sub {
			logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
			my $s = shift;
			$s->__verify_private() if ( $p );
			$accessors{"$s"}{$method} = shift( @_ );
			return;
		};

		# Make the getter as well
		*{ "${class}::${p}get_${method}" } = sub {
			logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
			my $s = shift;
			$s->__verify_private() if ( $p );
			return $accessors{"$s"}{$method} || undef;
		};

		# Since it's the first time here, we'll generare the method they are looking
		# for and return relative to the request
		my $caller = "${p}${action}_${method}";
		return $self->$caller( @_ );
	}
}

{
	my %class_cache;
	sub __verify_private {
		logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );
		my ( $self ) = @_;

		die "Attempted access of private method outside of class hierarchy" unless(
			( caller( 1 ) )[0]->isa( __PACKAGE__ ) );

		return 1;		
	}
}

package Base::Class::clone;

use strict;
use warnings;

sub clone {
	my $c = shift;

	return ( ref( $c ) )
		? ( ref( $c ) eq 'ARRAY' )
			? [ @$c ]
			: ( ref( $c ) eq 'HASH' )
				? { %$c }
				: $c
		: $c;
}

2 != 42;

__END__

=head1 NAME

Base::Class - A very simple and functional inside out base class 

=head1 SYNOPSIS

	# Simply call a new method.  Defined at C<Base::Class>.
	my $foo = Foo::Bar->new();

	# Notice that you can 'seed' accessors to what ever you would like
	# by calling the C<Base::Class::seed> method with a hash-ref as an argument.
	$foo->seed( { 'accessor' => 'value' } );

	# This will pile a C<Data::Dumper::Dumper> output to STDOUT.
	$foo->dump();

	# This is a custom method defined in Foo::Bar (see below, inline)
	$foo->custom_method();

	package Foo::Bar;

	use strict;
	use warnings;

	use base qw( Base::Class );

	# Use custom bit-mask log leveling to amp up the log level.
	# If you base if off the value in C<Base::Class>, you will have the
	# ability to set your LOG_LEVEL based off environment variables.
	use constant LOG_LEVEL => Base::Class::LOG_LEVEL | 0;
	
	# The init method is called at instantiation.  This is overridden
	# rather than C<Base::Class::new> since you will already have a blessed
	# scalar reference at this point.
	sub _init {
		my $self = shift;

		# Do some stuff at object instantiation

		return $self->SUPER::_init( @_ );
	}

	# Some arbatrary custom method
	sub custom_method {
		my ( $self ) = @_;
		$self->logger( 'say something' ) if ( LOG_LEVEL & Base::Class::LOG_LEVEL );

		$self->get_something( 'some string' );
		print $self->set_something() . "\n";

		return;
	}
	

=head1 DESCRIPTION

=head2 Why another base class?

First off, this isn't anything new or ground breaking.  Included with the standard install of Perl,
you will find a root class; CPAN as well has a couple modules that will allow for the use of a generalized
abstract base class.  These include C<UNIVERSAL>, C<Base::Class> and C<Pakcage::Base>.  With the exception
of UNIVERSAL, they are very Base common implementations for common things that 'every class' does.  However,
in my own personal projects, I have found the mentioned files are simply not enough.  I'll quickly explain
the features this abstract class has where (I believe) the others fall short (relative to what I want out of
a base-class).

	 Problem: I like strict-ish encapsulation.  I don't like accessing data via a blessed hash ref.
	Solution: Base::Class.pm is a blessed scalar reference, not a hash reference.  Secondly, to access
                  data, you simply call an un-defined getter and setter (take a look at the ACCESSOR METHOD section).
                  Using the mgic of Perl AUTOLOAD, will dynamically add a method reference to the class
                  allowing for the dynamic generation of mnew accessor methods

	 Problem: I like having private methods stay private
	Solution: If a method is pre-fixed with a '_', each call to the method will run through conditions
	          that will test to make sure the caller() is of the same type as the callee.  Will die otherwise

	 Problem: I LOVE logging, but I hate how each logging call takes up some CPU when realisticaly I don't 
	          want to log everything all of the time.
	Solution: Using the Perl optimizer, we can optimize out our logging routines at compile time.  Take a look
	          at C<Base::Class::logger> for more details on how this works.

	 Problem: There are a number of other similar implementations currently on CPAN which are very good, yet
                  have either been too little or too much for my needs.  Given this, I took it upon myself to
                  make a new one.  It has a Baser interface than the likes of C<Base::Class> and/or C<Object::InsideOut>.
                  Similarly, modules such as C<Object::InsideOut> are a little too overboard for Base applications
                  that want Base interfaces into each of the object therein.
        Solution: This module is intended be as Base as all get-out.  Takes nothing at instantiation, integrates
                  simplistic logging, with built in optimizations, allows for Base copying of structures, etc.
                  (more below in the rest of the POD)

Given these Base problems and found solutions, this came around.  Now, that it has become the base of most
of my personal projects, I figured it was time I released it for others to play with.  Also, it gives some middle
ground between very light and heavy Inside-out objects

=head2 The real description

C<Base::Class> is intended to act as a generalized base class for OO Perl implementations.  Containing no
required dependancies, has some build in features that are generally nice to have using a number
of abilities within Perl.

For instance, accessor methods do not have to be stubbed for every public and private method call.
Simply calling $self->get_anything() will, using AUTOLOAD, attach the C<get_something> and C<set_something>
methods to the class, the allowing for the dynamic building of method calls.  Similarly, adding a '_' to
the method call will enforce a specific level of 'privateness', whereas only a class within the @ISA tree
will be allowed to access that particular method (must be a sub-class).

Similarly, optimized logging can be added very easily.  Using Perl compile rules, when a conditional is
used with constants and the conditional is FALSE, the compiled Perl will not generate an opt code for the
conditinal block.

	http://perldoc.perl.org/constant.html#DESCRIPTION

Therefore, using the defined C<Base::Class::LOG_LEVEL> with pre-defined log levels within the base class,
you are able to turn up the logging globally to the application (modifying the C<Base::Class::LOG_LEVEL>)
or for a single object (modifying LOG_LEVEL at the overridden sub-class).

=head1 EXPORT ROUTINES

=head2 logger

See the method definition for more details on this EXPORTED function

Subsiquently, this is also an (the only) exported function within the C<Base::Class> definition.  When used
with constants defined within the class as well, allow for an optimized methodology of logging within
an application.

First, I recommend reviewing the following URL:

	http://perldoc.perl.org/constant.html#DESCRIPTION

You will read:

	... When a constant is used in an expression, perl replaces it with its value at compile time, and may then
	optimize the expression further.  In particular, any code in an if(CONSTANT) block will be optimized away
	if the constant is false ...

Using this fun optimization trick, C<Base::Class> has a number of logging constants you can use to turn on and off different
levels of logging.  The following are all the constants and their definitions:

	use constant NO_LOG    => 0b00000; # 0
	use constant DEBUG     => 0b00001; # 1
	use constant TRACE     => 0b00010; # 2
	use constant WARNING   => 0b00100; # 4
	use constant ERROR     => 0b01000; # 8
	use constant CRITICAL  => 0b10000; # 16

Notice each of the values are bit-masked.  I wil get into this a little later.

There are a number of ways you can utilize this feature.  I will recommend one, go into it in further detail,
and hopefully you will be able to catch on.

At C<Base::Class>, the local LOG_LEVEL constant is defined in one of two ways.  If the environtment variable 'LOG_LEVEL'
is defined, the C<Base::Class::LOG_LEVEL> constant will be set to that value.  Otherwise, the C<Base::Class::LOG_LEVEL> variable
will be set a level of ERROR and CRITICAL (using a bit-wise OR).  Similar to the following:

	$ENV{'LOG_LEVEL'} ||= ERROR | CRITICAL;
	use constant LOG_LEVEL => $ENV{'LOG_LEVEL'};

Following this assignment and throughout the C<Base::Class> code, you will find tests from both the defined LOG_LEVEL
and the different levels defined in the class.  Following the next example:

	logger( 'trace', 'enter' ) if ( LOG_LEVEL & TRACE );

If the current LOG_LEVEL has the TRACE bit 'on', Perl will *not* optimize that call out and will call C<Base::Class::logger>.
However, of course, by default, TRACE is not turned on.  This is why I recommend defining the LOG_LEVEL with a
bit-wise OR, which will force multiple bits to be 'on'.  Therefore:

	use constant LOG_LEVEL => ERROR | CRITICAL | TRACE;

Will turn on ERROR, CRITICAL and TRACE level logging if used in the context of my explenation.  More information
about this, review documentation relative to bitwise operations in Perl.

Subsiquently, this could be used in all implementing classes as well.  This is why C<Base::Class::logger> is an Exported.
There are a number of ways to ensure you have the logger method contained within all sub-classes of C<Base::Class>.
Here are some examples:

	# Package one example
	package One;

	use strict;
	use warnings;
	use base qw( Base::Class );
	use constant LOG_LEVEL => Base::Class::LOG_LEVEL | Base::Class::TRACE;

	sub some_method { 
		my $self = shift;
		$self->logger( 'trace' ) if ( LOG_LEVEL & Base::Class::TRACE );
	}

	# Package two example
	package Two

	use strict;
	use warnings;
	use base qw( Base::Class );
	use Base::Class qw( logger );
	use constant LOG_LEVEL => Base::Class::TRACE;

	sub some_method {
		logger( 'trace' ) if ( LOG_LEVEL & Base::Class::TRACE );
	}

	# Package three example
	package Three;

	use strict;
	use warnings;
	use base qw( Base::Class );
	use constant LOG_LEVEL => Base::Class::LOG_LEVEL | Base::Class::TRACE;

	{
		no strict 'refs';
		*logger = \&Base::Class::logger;
	}

	sub some_method {
		logger( 'trace' ) if ( LOG_LEVEL & Base::Class::TRACE );
	}

	# Package four example
	package Four;

	use strict;
	use warnings;
	use base qw( Base::Class );
	use constant LOG_LEVEL => Base::Class::TRACE | 0 | 0b00;

	eval( "sub logger{ return Base::Class::logger( @_ ); }" );

	sub some_method {
        logger( 'trace' ) if ( LOG_LEVEL & Base::Class::TRACE );
    }

As you can see, there are a few ways you can do this.  That's why we all love Perl, right ;)  Anyhoo, you can also
see in the above examples that I am using the same optimization features defined earlier.  By defining a local
LOG_LEVEL to the sub-class, I can turn up and down logging appropriately within a particular class (or object(s)).
This is a nice feature if you don't want your entire application to start spewing out stuff about who was where
when and on what line.

The logger output will follow the following format:

	"[%s]\t%-s%-05d%-s\n",

With the following parameters:

	[TIME] Caller::from 	line 	message 

=head1 OBJECT METHODS

=head2 new

* THIS METHOD IS NOT INTENDED TO BE OVERRIDEN FOR OBJECT MANIPULATION *

For the generation of singleton objects or a similar implementation where the use of the C<Base::Class::new>
method would be handy, the override of the method is certainly accepted.  However, if you are simply
interested in adding some accessor data to the object upon instantiation, the overriden C<Base::Class::_init>
has been provided.

A call to new will simply return a blessed scalar reference to the particular sub-class of C<Base::Class>.
The object will NOT be a reference to a hash since the idea of C<Base::Class> is to keep strong data
encapsulation and class privacy.  This is not nearly as easy with a hash-ref.  Given this, to allow
for ease of programming, similar to a hash reference object structure, view the ACCESSOR METHODS
section of the documentation.

	my $foo_object = Foo->new();

	package Foo;

	use base qw( Foo );

=head2 _init

This method, rather than C<Base::Class::new> is fully intended to be overridden by all sub-classes as necessary.
This is handy, rather than passing a string of the name-space for the class, the first parameter of @_ will
be a reference to the current object.

	package Foo;

	use base qw( Foo );

	sub _init {
		my $self = shift;

		$self->set_some_attribute( 'to a value' );

		return $self->SUPER::_init( @_ );
	}

=head2 seed

Accepting a reference to a hash, this method will set all the values of the hash to PUBLIC
and representative methods of the keys.  Thus:

	{ 'key' => 'value' }

When passed to the method, will be accessable via

	my $value = $self->_get_key();

Where key was named from the key of the hash reference and value is a direct reference to the value
of key from the above hash.

	my $foo = Foo->new();
	$foo->seed( { 'key' => 'value' } );

	my $key = $foo->_get_value();

	package Foo;

	use base qw( Foo );

A second, and optional parameter to the method, is a boolean flag that will tell the seeding call
to represent the methods PRIVATELY, adhiering to the private rules applied to the ACCESSOR METHOD
paradigm.

	$foo->seed( { 'key' => 'value', }, 1 );

For more infomration on the finer details of how or why this works, take a look into the ACCESSOR METHOD
section of the document.

=head2 dump

Simply, will print a particular representation of the object to STDERR.  The output of this method
will not be wrapped in the C<Base::Class::logger> method, therefore not adding the formatting or otherwise
provided from the method.

Depending on the availablility of the C<Data::Dumper> module, will use The C<Data::Dumper::Dump>
routine to dump a hash looking representation of all the internal ACCESSOR attributes within the
object.  If the dumper is not available, will attempt a stringified version of the class (most likely
the object's referential memory location).

	my $foo = Foo->new();
	$foo->dump();

	# Now, take a look at STDERR
	
	package Foo;

	use strict;
	use warnings;

	use base qw( Base::Class );

=head2 hashify

Similar to the C<Base::Class::dump> method, will gather a hash representation of the object and return
a reference to that hash.

	use Data::Dumper;

	my $foo      = Foo->new();
	my $foo_hash = $foo->hashify();

	print Dumper( $foo_hash );
	
	package Foo;

	use strict;
	use warnings;

	use base qw( Base::Class );

=head2 copy

Simply, will return a clone of the calling object with a blessed reference to a new object
of the same type with the same data encapsulated in the same generated methods.

Uses an embedded package, C<Base::Class::clone> which will, by default, simply create a shallow
copy of th current structure and it's class contents.  However, you are allowed to change
this interface externally to the class by modifying the stash variable, C<$CLONE>.  For
example:

	$Base::Class::CLONE     = 'Clone';
	$Base::Class::CLONE_SUB = 'clone';

This will, then, use the C<Clone> CPAN module and run the clone routine against the
hashieifed object rather than the embedded shallow cloning otherwised ran.  On the
same note, the object will not automatcially download anything from CPAN, so if you
create a class dependancy on an external module that is not in your current Perl
disto CORE, then you will have to download it.  Using this example, you would
have to install C<Clone> before attempting.

	use Data::Dumper;

	my $foo = Foo->new();

	my $r = { 'key' => 1 };
	$foo->set_ref( $r );
	
	my $copy_of_foo = $foo->copy();
	$copy_of_foo->get_ref()->{'value'}++;

	print Dumper( [ $r, $foo->hashify(), $copy_of_foo->hashify() ] );

	# Will demonstrate that the modification of the $copy_of_foo will
	# have the value incremented whereas the other references will not
	
	package Foo;

	use strict;
	use warnings;

	use base qw( Base::Class );

=head1 ACCESSOR METHODS

The use of the accessor methods were/are the primary reason I created this module.
Simply, by following the following regular expression with method calls, you will
be able to use dynamically created accessor methods at the object level.

	qr/::(_)?([gs]et)_(\w+)$/s;

The useage of this pattern is applied in the AUTOLOAD routine.  All method calls
that do not follow this pattern will die as Perl would normally die when an undefined
method is called on the objet.

Additively, rather than continuing to call AUTOLOAD every time that particular
accessor method is created, a natural subroutine will be referenced to the name space
of the class.  Thus, subsequent calls to either the 'getter' or 'setter' of the
same name will be direct method calls to the object, rather than running through
the overhead of run-time AUTOLOAD.

Using the example:

	my $foo = Base::Class->new();

	$foo->set_something( 'something' );
	print $foo->get_something();

The 'set_something' method will not be found defined in the class, Perl will jump
to the AUTOLOAD routine.  Finding the method name fit's the pattern expalined
earlier, will then reference not only set_something but get_something (every setter
gets a getter) to the object.  Therefore, the call to get_something on the next line
will not have to hit the AUTOLOAD routine.

Another fun feature of this routine is to 'privatize' method calls.  Therefore,
by simply appending the '_' to the beginning of a method will ensure the calling
package is a sub-class or the class before allowing access to the method.  In fact,
if an external object tries to call a 'private' method, the application will die.
Unfortunately, this will be a run-time exception; nevertheless will continue with
the paradigm allowed.

=head1 Configuration Variables

=over

=item $Base::Class::CLONE

Will define the mode of which to use while copying the current object.  For more
information on this, please refer to the documentation relative to C<Base::Class::copy>

This value will default to 'Base::Class::clone', which is an internallyy define cloning
mechagnism.

=item $Base::Class::CLONE_SUB

Will define the routine that will be used within the $Base::Class::CLONE of which to call
when copying the current object.

This value will default to 'clone', refering to the clone routnine in the internally defined
Base::Class::clone module.

The C<Base::Class::clone::clone> will only clone a shallow copy of the object, rather than
a deep copy.  For deep copying, it is recommended to use 'Clone::clone' or 'Storable::dclone'.

=item $Base::Class::STRICT_LOGGING

This is the idea of allowing the C<Base::Class::logger> method validate the log level before
allowing the logging of a particular message. When 'off' (evalates to false in Perl), the
logging method will check the last value of the @_, testing against the current log level
defined at C<Base::Class::LOG_LEVEL>, rather than assuming the developer will take advantae
of the optimizations defined in C<Base::Class::logger>.

By default, Strict Logging is alwasy 'on', ththus avoiding this internal check; falling back
to what is defined withint he C<Base::Class::loger> documentation.

Example of this configuration being:

	package Foo;

	use strict; use warnings;
	use base qw( Base::Class ); # ima Base::Now!

	use constant LOG_LEVEL => Base::Class::LOG_LEVEL;
	
	# Whereas the documentation will define the following usage
	# of the log leveling and logger routine to be the most
	# optimal and preferred:
	logger( 'some message' ) if ( LOG_LEVEL & Base::Class::LOG_LEVEL );

	# Where the use of this configuration variable will allow for the
	# developer to not have to know anything about the bit-masked
	# values and optimizations, where the last parameter will be evaluated
	# to determine if the class will log or not...

	# This will turn off strict logging
	$Base::Class::STRICT_LOGGING = 0; # Or anything 'False'

	# Now we have to pass in the level we want this messgae to be logged at
	logger( 'some message', Base::Class::TRACE );

=back

=head1 SEE ALSO

=over

=item Data::Dumper

Not a dependancy of this module, yet always a good read.  Will be used if/when
installed on the machine.

=item POSIX

Not a dependancy of this module, yet always a good read.  Will be used if/when
installed on the machine.

=item Exporter

Not a dependancy of this module, yet always a good read.  Will be used if/when
installed on the machine.

=head1 DEPENDENCIES

=item UNIVERSAL

Used in a couple of places to determine the @ISA class hierachy, therefore is
required.  However, this is a very standard install in Perl being that it is
the base class of all objects (including this one), therefore I felt it
safe to let UNIVERSAL slide whereas I didn't for any others.  I belive
this was released with 5.0.1, so we should be fine here.

=item Perl 5.6.1

For now, this is as far back as I knew I could go.  Moving foward I will
try to make sure this can go back to first revs of 5.

=back

=head1 WARNINGS

=over

=item Requires 5.6.1

I think this is the oldest version of Perl that can currently use this module.
Movinf forward, I will do everything I can to remove this dependency.

=item threads

I haven't tested this class in a threadded environment.  Let me know if you
have any issues with this

=back

=head1 AUTHOR

Trevor Hall, E<lt>hallta@gmail.comE<gt>
	
	Perlmonks:
	http://perlmonks.org/?node=wazzuteke

	CPAN:
	http://search.cpan.org/~wazzuteke/

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Trevor Hall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later or earlier version of Perl 5 you may have
available.

=cut
