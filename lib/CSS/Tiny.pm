package CSS::Tiny;

# This package reads and writes CSS files, using as little code as possible.
# The module CSS.pm has a memory overhead of 2.6 meg, which is an amazing
# amount of memory to use for something so simple.
#
# The metric used is the memory overhead of the module, excluding 
# dependencies that are highly likely to be loaded anyway, such as File::Spec.

use strict;
use Fcntl ();

# Set the VERSION
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.2';
}

# Create the error string
use vars qw{$errstr};
BEGIN { $errstr = '' }

# Create a new CSS::Tiny object
sub new { bless {}, $_[0] }

# Reads a css file
sub read {
	$errstr = '';
	my $class = shift;

	# Check the file
	my $file = shift or return $class->_error( 'You did not specify a file name' );
	return $class->_error( "File '$file' does not exist" ) unless -e $file;
	return $class->_error( "'$file' is a directory, not a file" ) unless -f $file;
	return $class->_error( "Insufficient permissions to read '$file'" ) unless -r $file;

	# Create the base object
	my $self = $class->new();
	
	# Open the file
	sysopen( CSS, $file, Fcntl::O_RDONLY() ) 
		or return $class->_error( "Failed to open file '$file': $!" );
	flock( CSS, Fcntl::LOCK_SH() ) 
		or return $class->_error( "Failed to get a read lock on the file '$file'" );
	
	# Read the contents of the file
	my $contents;
	{
		local $/ = undef;
		$contents = <CSS>;
	}
	
	# Close the file
	flock( CSS, Fcntl::LOCK_UN() )
		or return $class->_error( "Failed to unlock the file '$file'" );	
	close( CSS ) or $class->_error( "Failed to close the file '$file': $!" );

	# Flatten whitespace
	$contents =~ tr/\n\t/  /;
	
	# Remove C-style comments. e.g. /* comment */ 
	$contents =~ s!/\*.*?\*\/!!g;

	# Split into styles
	foreach ( grep { /\S/ } split /(?<=\})/, $contents ) {
		unless ( /^\s*([^{]+?)\s*\{(.*)\}\s*$/ ) {
			return $class->_error( "Invalid or unexpected style data '$_'" );
		}
		
		# Split in such a way as to support style groupings
		my $style = $1;
		$style =~ s/\s{2,}/ /g;
		my @styles = grep { /\S/ } split /\s*,\s*/, $style;
		foreach ( @styles ) { $self->{$_} = {} }
		
		# Split into properties
		foreach ( grep { /\S/ } split /\;/, $2 ) {
			unless ( /^\s*([\w._-]+)\s*:\s(.*?)\s*$/ ) {
				return $class->_error( "Invalid or unexpected style data '$_' in style '$style'" );
			}
			foreach ( @styles ) { $self->{$_}->{$1} = $2 }
		}
	}	
	
	return $self;
}

# Write a css file
sub write {
	$errstr = '';
	my $self = shift;
	my $file = shift;
	my $mode = shift || 0666;
	unless ( $file ) {
		return $self->_error( 'No file name provided to save to' );
	}

	# Get the contents of the file
	my $contents = $self->write_string();
	
	# Open the file
	sysopen ( CSS, $file, Fcntl::O_WRONLY()|Fcntl::O_CREAT()|Fcntl::O_TRUNC(), $mode )
		or return $self->_error( "Failed to open file '$file' for writing: $!" );
	flock( CSS, Fcntl::LOCK_EX() )
		or return $self->_error( "Failed to get a write lock on the file '$file'" );
	
	print CSS $contents;
	
	# Close the file
	flock( CSS, Fcntl::LOCK_UN() )
		or return $self->_error( "Failed to unlock the file '$file'" );	
	close( CSS ) or $self->_error( "Failed to close the file '$file': $!" );

	return 1;	
}

# Generates the contents of a css file
sub write_string {
	my $self = shift;
	my @contents = ();
	
	# Iterate over the styles
	foreach my $style ( sort keys %$self ) {
		push @contents, "$style {";
		push @contents, map { "\t$_: $self->{$style}->{$_};" } sort keys %{ $self->{$style} };
		push @contents, "}";
	}
	
	return join '', map { "$_\n" } @contents;
}

# Error handling
sub errstr { $errstr }
sub _error { $errstr = $_[1]; return undef }

1;

__END__

=pod

=head1 NAME

CSS::Tiny - Read/Write .css files with as little code as possible

=head1 SYNOPSIS

    # In your .css file
	H1 { color: blue }
	H2 { color: red; font-family: Arial }
	.this, .that { color: yellow }
	
    # In your program
    use CSS::Tiny;

	# Create a css stylesheet
	my $CSS = CSS::Tiny->new();

	# Open a css stylesheet
	$CSS = CSS::Tiny->read( 'style.css' );

    # Reading properties
	my $header_color = $CSS->{H1}->{color};
	my $header2_hashref = $CSS->{H2};
	my $this_color = $CSS->{'.this'}->{color};
	my $that_color = $CSS->{'.that'}->{color};

    # Changing styles and properties
	$CSS->{'.newstyle'} = { color => '#FFFFFF' }; # Add a style
	$CSS->{H1}->{color} = 'black';                # Change a property
	delete $CSS->{H2};                            # Delete a style

    # Save a css stylesheet
    $CSS->write( 'style.css' );

=head1 DESCRIPTION

CSS::Tiny is a perl class to read and write .css stylesheets with as 
little code as possible, reducing load time and memory overhead. CSS.pm
requires about 2.6 meg or ram to load, which is a large amount of 
overhead if you only want to do trivial things.
Memory usage is normally scoffed at in Perl, but in my opinion should be
at least kept in mind.

This module is primarily for reading and writing simple files, and anything
we write shouldn't need to have documentation/comments. If you need something
with more power, move up to CSS.pm.

=head2 CSS Feature Support

CSS::Tiny supports grouped styles of the form C<this, that { color: blue }>
in reads correctly, ungrouping them into the hash structure. However, it will
not restore the grouping should you write the file back out. In this case, an
entry in the original file of the form

C<H1, H2 { color: blue }>

would become

C<H1 { color: blue }
H2 { color: blue }>

CSS::Tiny handles nested styles of the form C<P EM { color: red }> in
reads and writes correctly, making the property available in the form

C<$CSS->{'P EM'}->{color}>

CSS::Tiny ignores comments of the form C</* comment */> on read, however
these comments will not be written back out to the file.

=head1 CSS FILE SYNTAX

Files are written in a highly human readable form, as follows

    H1 {
        color: blue;
    }
    .this {
    	color: red;
    	font-size: 10px;
    }
    P EM {
    	color: yellow;
    }

=head1 METHODS

=head2 new()

The constructor C<new()> creates and returns an empty CSS::Tiny object.

=head2 read( $filename )

The C<read()> constructor reads a css stylesheet, and returns a new CSS::Tiny
object containing the properties in the file. Returns the object on success.
Returns C<undef> on error.

=head2 write()

The C<write( $filename )> generates the stylesheet for the properties, and 
writes it to disk. Returns true on success. Returns C<undef> on error.

=head2 write_string()

Generates the stylesheet for the object and returns it as a string.

=head2 errstr()

When an error occurs, you can retrieve the error message either from the
C<$CSS::Tiny::errstr> variable, or using the C<errstr()> method.

=head1 SUPPORT

Contact the author

=head1 AUTHOR

        Adam Kennedy ( maintainer )
        cpan@ali.as
        http://ali.as/

=head1 SEE ALSO

L<CSS>, http://www.w3.org/TR/REC-CSS1

=head1 COPYRIGHT

Copyright (c) 2002 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
