#!/usr/bin/perl

# Formal testing for CSS::Tiny

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec ();
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( File::Spec->catdir(
			File::Spec->updir,
			File::Spec->updir,
			'modules',
			) );
	}
}

use Test::More tests => 25;

# Set up any needed globals
use vars qw{$loaded};
BEGIN {
	$loaded = 0;
	$| = 1;
}




# Check their perl version
BEGIN {
	ok( $] >= 5.005, "Your perl is new enough" );
}
	




# Does the module load
END { ok( 0, 'CSS::Tiny loads' ) unless $loaded; }
use CSS::Tiny;
$loaded = 1;
ok( 1, 'CSS::Tiny loads' );




# Test trivial creation
my $Trivial = CSS::Tiny->new();
ok( $Trivial, '->new returns true' );
ok( ref $Trivial, '->new returns a reference' );
ok( isa( $Trivial, 'HASH' ), '->new returns a hash reference' );
ok( isa( $Trivial, 'CSS::Tiny' ), '->new returns a CSS::Tiny object' );
ok( scalar keys %$Trivial == 0, '->new returns an empty object' );

# Try to read in a config
my $Config = CSS::Tiny->read( 'test.css' );
ok( $Config, '->read returns true' );
ok( ref $Config, '->read returns a reference' );
ok( isa( $Config, 'HASH' ), '->read returns a hash reference' );
ok( isa( $Config, 'CSS::Tiny' ), '->read returns a CSS::Tiny object' );

# Check the structure of the config
my $expected = {
	H1 => { color => 'blue' },
	H2 => { color => 'red', 'font-height' => '16px' },
	'P EM' => { this => 'that' },
	'A B' => { foo => 'bar' },
	'C D' => { foo => 'bar' },
	};
bless $expected, 'CSS::Tiny';
is_deeply( $Config, $expected, '->read returns expected structure' );

# Add some stuff to the trivial stylesheet and check write_string() for it
$Trivial->{H1} = { color => 'blue' };
$Trivial->{'.this'} = {
	color => '#FFFFFF',
	'font-family' => 'Arial, "Courier New"',
	'font-variant' => 'small-caps',
	};
$Trivial->{'P EM'} = { color => 'red' };

my $string = <<END;
P EM {
	color: red;
}
H1 {
	color: blue;
}
.this {
	color: #FFFFFF;
	font-family: Arial, "Courier New";
	font-variant: small-caps;
}
END

my $Read = CSS::Tiny->read_string( $string );
ok( $Read, '>read_string() returns true' );
is_deeply( $Read, $Trivial, '->read_string() returns expected' );

my $generated = $Trivial->write_string();
ok( length $generated, '->write_string returns something' );
ok( $generated eq $string, '->write_string returns the correct file contents' );

# Try to write a file
my $rv = $Trivial->write( 'test2.css' );
ok( $rv, '->write returned true' );
ok( -e 'test2.css', '->write actually created a file' );

# Clean up on unload
END {
	unlink 'test2.css';
}

# Try to read the config back in
$Read = CSS::Tiny->read( 'test2.css' );
ok( $Read, '->read of what we wrote returns true' );
ok( ref $Read, '->read of what we wrote returns a reference' );
ok( isa( $Read, 'HASH' ), '->read of what we wrote returns a hash reference' );
ok( isa( $Read, 'CSS::Tiny' ), '->read of what we wrote returns a CSS::Tiny object' );

# Check the structure of what we read back in
is_deeply( $Trivial, $Read, 'We get back what we wrote out' );		





#####################################################################
# Check that two identical named styles overwrite-by-property, rather than
# replace-by-style, so that styles are relatively correctly merged.

my $mergable = <<'END_CSS';
FOO {  test1: 1; }
FOO {  test2: 2; }
END_CSS

my $merged = CSS::Tiny->read_string( $mergable );
ok( $merged, "CSS::Tiny reads mergable CSS ok" );
is_deeply( $merged, { FOO => { test1 => 1, test2 => 2 } }, "Mergable CSS merges ok" );

1;
