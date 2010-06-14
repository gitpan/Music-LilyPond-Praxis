# -*- Perl -*-
#
# Class for sets of musical notes (and maybe other objects from a
# parsed score?).
#
# Copyright 2010 by Jeremy Mates.
#
# This module is free software; you can redistribute it and/or modify it
# under the Artistic license.

package Music::LilyPond::Set;

use strict;
use warnings;

use Carp qw/croak/;
use List::Util                        ();
use Music::LilyPond::Scale::Chromatic ();
use Scalar::Util                      ();

our $VERSION = '0.01';

########################################################################
#
# Utility Routines

my $_parse_elements = sub {
  my $self   = shift;
  my $result = 1;
  my $msg    = 'ok';

  if (@_) {
    my $count = 0;
    while ( my $element = shift ) {
      next if !defined $element;
      if ( Scalar::Util::blessed($element) and $element->can('clone') ) {
        push @{ $self->{_list} }, $element;
      } elsif ( $element =~ m/^[abcdefg]/ ) {
        push @{ $self->{_list} },
          Music::LilyPond::Scale::Chromatic->new($element);
      } else {
        $msg    = 'unsupported element at index ' . $count;
        $result = 0;
      }
    } continue {
      ++$count;
    }
  }

  return $result, $msg;
};

########################################################################
#
# Class Methods

sub new {
  my $class = shift;
  my $self = { _list => [] };

  my ( $result, $msg ) = $_parse_elements->( $self, @_ );
  if ( !$result ) {
    croak($msg);
  }

  bless $self, $class;
  return $self;
}

########################################################################
#
# Instance Methods

sub clone {
  my $self = shift;
  my $class = shift || ref($self);

  my $new_self = { _list => [] };
  my $count = 0;
  for my $element ( @{ $self->{_list} } ) {
    if ( Scalar::Util::blessed($element) and $element->can('clone') ) {
      push @{ $new_self->{_list} }, $element->clone;
    } else {
      croak( 'unsupported element at index ' . $count );
    }
    ++$count;
  }
  bless $new_self, $class;

  return $new_self;
}

sub append {
  my $self = shift;
  my ( $result, $msg ) = $_parse_elements->( $self, @_ );
  if ( !$result ) {
    croak($msg);
  }
  return $self;
}

sub clear {
  my $self = shift;
  $self->{_list} = [];
  return $self;
}

sub get_list {
  my $self = shift;
  return wantarray ? @{ $self->{_list} } : $self->{_list};
}

sub inversion {
  my $self = shift;
  my $axis = shift;
  for my $i ( 0 .. $#{ $self->{_list} } ) {
    if ( Scalar::Util::blessed( $self->{_list}->[$i] )
      and $self->{_list}->[$i]->can('invert') ) {
      $self->{_list}->[$i]->invert( defined $axis ? $axis : () );
    }
    # TODO may want an error or callback, though could end up with sets
    # that contain non-note objects, in which case we don't want a
    # warning emitted.
  }
  return $self;
}

sub retrograde {
  my $self = shift;
  $self->{_list} = [ reverse @{ $self->{_list} } ];
  return $self;
}

sub shuffle {
  my $self = shift;
  $self->{_list} = [ List::Util::shuffle @{ $self->{_list} } ];
  return $self;
}

sub as_string {
  my $self = shift;
  my @parts;
  for my $element ( @{ $self->{_list} } ) {
    if ( Scalar::Util::blessed($element) and $element->can('as_string') ) {
      push @parts, $element->as_string;
    }
  }
  return join( q{ }, @parts );
}

1;

__END__

=head1 NAME

Music::LilyPond::Set - sets of notes or other objects

=head1 SYNOPSIS

  TODO

=head1 DESCRIPTION

TODO

Warning about references, and possible need to clone!

=head1 CLASS METHODS

=over 4

=item B<new>

TODO

=back

=head1 INSTANCE METHODS

=over 4

=item B<TODO>

TODO

=back

=head1 BUGS

No known bugs.

=head2 Reporting Bugs

Newer versions of this module may be available from CPAN.

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

=head2 Known Issues

No known issues.

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
