# -*- Perl -*-
#
# Methods to parse and alter LilyPond notes.
#
# Copyright 2010 by Jeremy Mates.
#
# This module is free software; you can redistribute it and/or modify it
# under the Artistic license.

package Music::LilyPond::Scale::Chromatic;

use strict;
use warnings;

use Carp qw/croak/;

our $VERSION = '0.03';

my $DEGREES_IN_SCALE = 12;

my %NOTE2NUM = (
  c => 0,
  d => 2,
  e => 4,
  f => 5,
  g => 7,
  a => 9,
  b => 11
);
my $NOTE_RE = '([' . join( '', keys %NOTE2NUM ) . '])((?:[ei]s)+)?';

my %NUM2NOTE = (
  0  => { is => 'c',   es => 'c' },
  1  => { is => 'cis', es => 'des' },
  2  => { is => 'd',   es => 'd' },
  3  => { is => 'dis', es => 'ees' },
  4  => { is => 'e',   es => 'e' },
  5  => { is => 'f',   es => 'f' },
  6  => { is => 'fis', es => 'ges' },
  7  => { is => 'g',   es => 'g' },
  8  => { is => 'gis', es => 'aes' },
  9  => { is => 'a',   es => 'a' },
  10 => { is => 'ais', es => 'bes' },
  11 => { is => 'b',   es => 'b' },
);

my $DEFAULT_ACCIDENTAL;

########################################################################
#
# Utility Functions

my $_parse_accidental = sub {
  my $string = shift;
  my $value;
  if ( $string =~ m/^-?\d+$/ ) {
    $value = $string < 0 ? -1 : $string > 0 ? 1 : 0;
  } elsif ( $string =~ m/^(?:is)+$/ or $string eq 'sharp' ) {
    $value = 1;
  } elsif ( $string =~ m/^(?:es)+$/ or $string eq 'flat' ) {
    $value = -1;
  }
  return $value;
};

my $_parse_note = sub {
  my $self       = shift;
  my $note       = shift;
  my $accidental = shift;

  if ( !exists $NOTE2NUM{$note} ) {
    return 0;
  }
  $self->{_note} = $NOTE2NUM{$note};

  my $sharp_or_flat = 0;
  if ( defined $accidental ) {
    # count "is" (sharp) or "es" (flat) in string. LilyPond uses
    # "isis" for double sharp, though this code supports probably
    # invalid input such as "isisises"
    # TODO if use m//g might need to fiddle with pos() if that
    # influences the new_lex...
    $sharp_or_flat += ( $accidental =~ tr/i// );
    $sharp_or_flat -= ( $accidental =~ tr/e// );
  }

  $self->{_note} += $sharp_or_flat;
  $self->{_accidental} = $sharp_or_flat < 0 ? -1 : $sharp_or_flat > 0 ? 1 : 0;

  return 1;
};

########################################################################
#
# Class Methods

sub new {
  my $class  = shift;
  my $string = shift;

  my $self = { _accidental => 0, _note => undef };
  my $result = 0;
  if ( defined $string and $string =~ m/$NOTE_RE/ ) {
    $result = $_parse_note->( $self, $1, $2 );
    croak('unable to parse note') if !$result;
  }

  bless $self, $class;
  return $self;
}

sub set_default_accidental {
  my $self   = shift;
  my $string = shift;
  if ( !defined $string ) {
    croak('set_default_accidental requires a value');
  }
  my $result = $_parse_accidental->($string);
  if ( !defined $result ) {
    croak('set_default_accidental passed unknown accidental value');
  }
  $DEFAULT_ACCIDENTAL = $result;
  return $self;
}

sub get_default_accidental {
  return $DEFAULT_ACCIDENTAL;
}

sub unset_default_accidental {
  my $self = shift;
  undef $DEFAULT_ACCIDENTAL;
  return $self;
}

########################################################################
#
# Instance Methods

sub parse {
  my $self   = shift;
  my $string = shift;

  my $result = 0;
  if ( defined $string and $string =~ m/$NOTE_RE/ ) {
    $result = $_parse_note->( $self, $1, $2 );
    croak('unable to parse note') if !$result;
  }
  return $self;
}

sub clone {
  my $self = shift;
  my $class = shift || ref($self);

  my $new_self = {%$self};
  bless $new_self, $class;
  return $new_self;
}

sub as_string {
  my $self = shift;
  if ( !defined $self->{_note} ) {
    croak('note was never defined');
  }

  my $note_value = $self->{_note} % $DEGREES_IN_SCALE;

  my $accidental_value =
    defined $DEFAULT_ACCIDENTAL ? $DEFAULT_ACCIDENTAL : $self->{_accidental};
  my $accidental_name = $accidental_value < 0 ? 'es' : 'is';

  return $NUM2NOTE{$note_value}->{$accidental_name};
}

sub get_accidental {
  return shift->{_accidental};
}

sub set_accidental {
  my $self   = shift;
  my $string = shift;
  croak('set_accidental requires a value') if !defined $string;
  my $value = $_parse_accidental->($string);
  croak('set_accidental passed unknown accidental value') if !defined $value;
  $self->{_accidental} = $value;
  return $self;
}

sub set_value {
  my $self  = shift;
  my $value = shift;
  croak('set_value requires an integer') if !defined $value;
  if ( $value !~ m/^-?\d+$/ ) {
    croak('value requires an integer');
  }
  $self->{_note} = $value % $DEGREES_IN_SCALE;
  return $self;
}

sub get_value {
  my $self = shift;
  if ( !defined $self->{_note} ) {
    croak('note was never defined');
  }
  return $self->{_note} % $DEGREES_IN_SCALE;
}

sub transpose {
  my $self  = shift;
  my $value = shift;
  croak('transpose requires an integer') if !defined $value;
  if ( $value !~ m/^-?\d+$/ ) {
    croak('transpose requires an integer');
  }
  $self->{_note} = ( $self->{_note} + $value ) % $DEGREES_IN_SCALE;
  return $self;
}

sub invert {
  my $self = shift;
  my $axis = shift;

  if ( defined $axis ) {
    my $axis_value = 0;
    if ( $axis =~ m/^\d+$/ ) {
      $axis_value = $axis % $DEGREES_IN_SCALE;
    } else {
      $axis_value = Music::LilyPond::Scale::Chromatic->new($axis)->get_value;
    }
    $self->{_note} = $axis_value + -1 * ( $self->{_note} - $axis_value );
  } else {
    $self->{_note} = $DEGREES_IN_SCALE - 1 - $self->{_note};
  }
  $self->{_note} %= $DEGREES_IN_SCALE;
  return $self;
}

1;

__END__

=head1 NAME

Music::LilyPond::Scale::Chromatic - methods to parse and alter LilyPond notes

=head1 SYNOPSIS

  my $note = Music::LilyPond::Scale::Chromatic->new('b');
  
  $note->transpose(1);
  my $value = $note->get_value;
  
  print $note->as_string;
  
  $note->invert();

=head1 DESCRIPTION

This module contains methods for parsing and applying musical operations
such as transposition on notes parsed from the LilyPond notation.

The module will throw an error in various conditions. These should be
caught with C<eval> blocks if necessary.

=head1 CLASS METHODS

=over 4

=item B<new> I<optional note>

Constructor method. Optionally accepts a string such as C<ces> that
represents a LilyPond note.

=item B<set_default_accidental> I<accidental>

Use this method to set a class-wide default on what accidental should be
used for output. The accidental can be specified as C<es> or C<is> as is
the default in LilyPond, or as C<sharp> or C<flat>.

By default, the sign (or sharp for neutral) of the original note will be
used, so that notes that were sharp remain sharp, and flats remain flat,
if necessary after transposition or inversion.

The default accidental setting (if any) is only considered during the
B<as_string> method call, and does not affect instance specific
accidental calls for particular notes.

=item B<get_default_accidental>

Returns the current class accidental setting, either -1 for flat, 0 for
neutral, though sharps will be used if necessary, or 1 for sharp.

=item B<unset_default_accidental>

Clears any custom accidental setting.

=back

=head1 INSTANCE METHODS

Most instance methods, with the notable exception of the C<get_*> and
C<as_string>, return the instance, allowing method call chains:

  $note->parse('c')->transpose(-6)->invert('d')->as_string;

=over 4

=item B<as_string>

Returns the note as a string value LilyPond expects, such as C<cis>. The
module tries to preserve sharps or flats from the original note should
the note have been transposed or otherwise changed, though this behavior
can be changed via a number of class or instance methods.

=item B<parse> I<note>

Parses a note like B<new>, except that a note is required.

=item B<transpose> I<degrees>

Adjusts the note by the specified number of degrees (semitones):

  $note->parse('c');
  $note->transposition(1);  # note is now 'cis'
  $note->transposition(-6); # note is now 'g'

=item B<invert> I<optional note axis>

Inverts the note, by default via modulus math, or with a note axis
supplied, mirrored around that note. Check C<eg/inversions> under the
module source for an illustration of how this works, as it may be
different from inversions in Music Theory.

=item B<clone>

Clones the object to create a new one.

=item B<get_accidental>

Returns the accidental setting for the note: -1, 0, or 1 for flats,
neutrals, or sharps, respectively.

=item B<set_accidental>

Sets the accidental style for the note. The accidental can be
specified as C<es> or C<is> as is the default in LilyPond, or as
C<sharp> or C<flat>.

=item B<set_value>

Sets the internal numeric value for the note. Does not specify the
accidental of the note, so an accidental method call may be necessary if
the note should be a flat:

  # hard way to say ->parse('des')
  $note->set_value(1)->set_accidental('flat');

=item B<get_value>

Returns the internal numeric value for the note.

=back

=head1 BUGS

No known bugs.
  
=head2 Reporting Bugs
  
Newer versions of this module may be available from CPAN.
  
If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

=head2 Known Issues

Only the LilyPond note names and whether the note is flat or sharp is
supported. Note durations or other ornaments are not supported. Check
C<eg/transpose> under the module source for a primitive lexer that can
parse notes out of simple LilyPond files.

=head1 SEE ALSO

=over 4

=item *

http://www.lilypond.org/

=item *

MIDI::Praxis::Variation

=item *

The C<eg> directory of this module distribution for sample scripts.

=back

=head1 AUTHOR

Jeremy Mates, E<lt>jmates@sial.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 by Jeremy Mates.

This program is free software; you can redistribute it and/or modify it
under the Artistic license.

=cut
