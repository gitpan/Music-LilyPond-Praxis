#!/usr/bin/perl
#
# Tests for Set.pm.

use strict;
use warnings;

use Data::Dumper qw(Dumper);
$Data::Dumper::Purity = 1;

use Test::More tests => 14;
BEGIN { use_ok('Music::LilyPond::Set') }
BEGIN { use_ok('Music::LilyPond::Scale::Chromatic') }

can_ok(
  'Music::LilyPond::Set', qw/
    new clone
    append clear get_list
    inversion retrograde shuffle/
);

my $s = Music::LilyPond::Set->new();
isa_ok( $s, 'Music::LilyPond::Set' );
is( @{ $s->get_list }, 0, 'check that list of notes is empty' );

{
  my $n1 = Music::LilyPond::Scale::Chromatic->new('e');
  my $n2 = Music::LilyPond::Scale::Chromatic->new('dis');
  my $t  = Music::LilyPond::Set->new( $n1, $n2 );
  is( @{ $t->get_list }, 2, 'check for notes in $t' );
}

$s = Music::LilyPond::Set->new(qw/e4 e e c2/);
is( @{ $s->get_list }, 4, 'check for notes in $s' );

my $first_note = ( $s->get_list() )[0];
isa_ok( $first_note, 'Music::LilyPond::Scale::Chromatic' );

$s->append( $first_note->clone->transpose(-2) );
is( @{ $s->get_list }, 5, 'check for new note' );
my $last_note = ( $s->get_list() )[-1];
is( $last_note->as_string, 'd', q{check that added note is 'd'} );

my $ss = $s->clone;
isa_ok( $ss, 'Music::LilyPond::Set' );

$s->inversion;
my $inverted = join q{ }, map $_->as_string, $s->get_list;
is( $inverted, 'gis gis gis c ais', 'check inverted notes' );

$ss->retrograde;

my $retro = join q{ }, map $_->as_string, $ss->get_list;
is( $retro,         'd c e e e', 'check retrograded notes' );
is( $ss->as_string, 'd c e e e', 'check retrograded notes via as_string' );

