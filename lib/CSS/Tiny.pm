package CSS::Tiny;

use strict;

use vars qw{$VERSION $errstr};
BEGIN {
	$VERSION = 1.01;
	$errstr = '';
}

# Create an empty object
sub new { bless {}, $_[0] }

# Create an object from a file
sub read {
	my $class = shift;

	# Check the file
	my $file = shift or return $class->_error( 'You did not specify a file name' );
	return $class->_error( "The file '$file' does not exist" ) unless -e $file;
	return $class->_error( "'$file' is a directory, not a file" ) unless -f $file;
	return $class->_error( "Insufficient permissions to read '$file'" ) unless -r $file;

	# Read the file
	local $/ = undef;
	open( CSS, $file ) or return $class->_error( "Failed to open file '$file': $!" );
	my $contents = <CSS>;
	close( CSS );

	# Parse the file and return
	return $class->read_string( $contents );
}

# Create an object from a string
sub read_string {
	my $class = shift;
	my $string = shift;

	# Create the empty object
	my $self = bless {}, $class;
	
	# Flatten whitespace and remove /* comment */ style comments
	$string =~ tr/\n\t/  /;
	$string =~ s!/\*.*?\*\/!!g;

	# Split into styles
	foreach ( grep { /\S/ } split /(?<=\})/, $string ) {
		unless ( /^\s*([^{]+?)\s*\{(.*)\}\s*$/ ) {
			return $class->_error( "Invalid or unexpected style data '$_'" );
		}
		
		# Split in such a way as to support grouped styles
		my $style = $1;
		$style =~ s/\s{2,}/ /g;
		my @styles = grep { /\S/ } split /\s*,\s*/, $style;
		foreach ( @styles ) { $self->{$_} = {} }
		
		# Split into properties
		foreach ( grep { /\S/ } split /\;/, $2 ) {
			unless ( /^\s*([\w._-]+)\s*:\s(.*?)\s*$/ ) {
				return $class->_error( "Invalid or unexpected property '$_' in style '$style'" );
			}
			foreach ( @styles ) { $self->{$_}->{$1} = $2 }
		}
	}	
	
	return $self;
}

# Write an object to a file
sub write {
	my $self = shift;
	my $file = shift or return $self->_error( 'No file name provided' );

	# Get the contents of the file
	my $contents = $self->write_string();
	
	# Write to the file
	open ( CSS, ">$file" ) or return $self->_error( "Failed to open file '$file' for writing: $!" );
	print CSS $contents;
	close( CSS );

	return 1;	
}

# Generates the contents of a css file
sub write_string {
	my $self = shift;
	
	# Iterate over the styles
	# Note: We use 'reverse' in the sort to avoid a special case related
	# to A:hover. See http://www.w3.org/TR/CSS2/selector.html#dynamic-pseudo-classes
	my $contents = '';
	foreach my $style ( reverse sort keys %$self ) {
		$contents .= "$style {\n";
		foreach ( sort keys %{ $self->{$style} } ) {
			$contents .= "\t$_: $self->{$style}->{$_};\n";
		}
		$contents .= "}\n";
	}
	
	return $contents;
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

=head2 read_string( $string )

The C<read_string()> constructor reads a css stylesheet from a string.
Returns the object on success, and C<undef> on error.

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
