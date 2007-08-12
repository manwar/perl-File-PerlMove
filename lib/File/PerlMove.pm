#!/usr/bin/perl -w

package File::PerlMove;

my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Sun Aug 12 23:55:24 2007
# Update Count    : 138
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use File::Basename;
use File::Path;

sub move {
    my $transform = shift;
    my $filelist  = shift;
    my $options   = shift || {};

    croak("Usage: move(" .
	  "operation, [ file names ], { options })")
      unless defined $transform && defined $filelist;

    $transform = build_sub($transform)
      unless ref($transform) eq 'CODE';

    # Process arguments.
    @$filelist = reverse(@$filelist) if $options->{reverse};
    foreach ( @$filelist ) {
	# Save the name.
	my $old = $_;
	# Perform the transformation.
	$transform->();
	# Get the new name.
	my $new = $_;

	# Anything changed?
	unless ( $old eq $new ) {

	    # Create directories.
	    if ( $options->{createdirs} ) {
		my $dir = dirname($new);
		unless ( -d $dir ) {
		    if ( $options->{showonly} ) {
			warn("[Would create: $dir]\n");
		    }
		    else {
			mkpath($dir, $options->{verbose}, 0777);
		    }
		}
	    }

	    # Dry run.
	    if ( $options->{verbose} || $options->{showonly} ) {
		warn("$old => $new\n");
		next if $options->{showonly};
	    }

	    # Check for overwriting target.
	    if ( ! $options->{overwrite} && -e $new ) {
		warn("$new: exists\n");
		next;
	    }

	    # Perform.
	    if ( $options->{symlink} ) {
		symlink($old, $new) || warn("$old: $!\n");
	    }
	    elsif ( $options->{link} ) {
		link($old, $new) || warn("$old: $!\n");
	    }
	    else {
		rename($old, $new) || warn("$old: $!\n");
	    }
	}
    }
}

sub build_sub {
    my $cmd = shift;
    # Special treatment for some.
    if ( $cmd =~ /^uc|lc|ucfirst$/ ) {
	$cmd = '$_ = ' . $cmd;
    }

    # Build subroutine.
    my $op = eval "sub { $cmd }";
    if ( $@ ) {
	$@ =~ s/ at \(eval.*/./;
	croak($@);
    }

    return $op;
}

1;

__END__

=head1 NAME

File::PerlMove - Rename files using Perl expressions

=head1 SYNOPSIS

  use File::PerlMove;
  move(sub { $_ = lc }, \@filelist, { verbose => 1 });

=head1 DESCRIPTION

File::PerlMove provides a single subroutine: B<File::PerlMove::move>.

B<move> takes three arguments: transform, filelist, and options.

I<transform> must be a string or a code reference. If it is not a
string, it is assumed to be a valid Perl expression that will be
turned into a anonymous subroutine that evals the expression. If the
expression is any of C<uc>, C<lc>, of C<ucfirst>, the resultant code
will behave as if these operations would modify C<$_> in-place.

When I<transform> is invoked it should transform a file name in C<$_>
into a new file name.

I<filelist> must be an array reference containing the list of file
names to be processed.

I<options> is a hash reference containing options to the operation.

Options are enabled when set to a non-zero (or otherwise 'true')
value. Possible options are:

=over 8

=item B<showonly>

Show the changes, but do not rename the files.

=item B<link>

Link instead of rename.

=item B<symlink>

Symlink instead of rename.

=item B<reverse>

Process the files in reversed order.

=item B<overwrite>

Overwrite existing files.

=item B<createdirs>

Create target directories if necessary.

=item B<verbose>

More verbose information.

=back

=head1 EXAMPLES

See B<pmv> for examples.

=head1 AUTHOR

Johan Vromans <jvromans@squirrel.nl>

=head1 COPYRIGHT

This programs is Copyright 2004,2007 Squirrel Consultancy.

This program is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License or the GNU General
Public License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

=cut
