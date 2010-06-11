#!/usr/bin/perl
#
# Tests for Chromatic.pm.

use strict;
use warnings;

use Test::More tests => 70;
BEGIN { use_ok('Music::LilyPond::Scale::Chromatic') }

can_ok(
  'Music::LilyPond::Scale::Chromatic', qw/
    new
    set_default_accidental
    get_default_accidental
    unset_default_accidental
    parse
    clone
    as_string
    get_accidental
    set_accidental
    set_value
    get_value
    transpose
    invert/
);

my $n = Music::LilyPond::Scale::Chromatic->new();
isa_ok( $n, 'Music::LilyPond::Scale::Chromatic' );

$n->set_value(0);
is( $n->get_value, 0,   'check note value' );
is( $n->as_string, 'c', 'check note name' );

is( $n->get_accidental, 0, 'check default accidental value' );

for my $note (qw/c aes fis/) {
  is( $n->parse($note)->as_string, $note, "check note parsing" );
}
# Double sharp/flats...
is( $n->parse('fisis')->get_value, 7 );
is( $n->parse('deses')->get_value, 0 );

for my $ref (
  { accidental => 'is',    expect => 1 },
  { accidental => 'sharp', expect => 1 },
  { accidental => 'es',    expect => -1 },
  { accidental => 'flat',  expect => -1 },
  { accidental => 0,       expect => 0 },
  ) {
  $n->set_accidental( $ref->{accidental} );
  is( $n->get_accidental, $ref->{expect}, "check accidental value" );
}

$n->set_value(15);
is( $n->get_value, 3, 'check modulated note value' );

# Inversion, no axis
for my $ref (
  [qw/0 11/], [qw/1 10/], [qw/2 9/], [qw/3 8/], [qw/4 7/],  [qw/5 6/],
  [qw/6 5/],  [qw/7 4/],  [qw/8 3/], [qw/9 2/], [qw/10 1/], [qw/11 0/]
  ) {
  is( $n->set_value( $ref->[0] )->invert->get_value,
    $ref->[1], "no axis inversion on " . $ref->[0] );
}

# Inversion around 4 axis (e)
for my $ref (
  [qw/0 8/], [qw/1 7/], [qw/2 6/], [qw/3 5/],  [qw/4 4/],   [qw/5 3/],
  [qw/6 2/], [qw/7 1/], [qw/8 0/], [qw/9 11/], [qw/10 10/], [qw/11 9/]
  ) {
  is( $n->set_value( $ref->[0] )->invert(4)->get_value,
    $ref->[1], "e-axis inversion on " . $ref->[0] );
}

# Inversion around "cis" axis
for my $ref (
  [qw/c d/],     [qw/cis cis/], [qw/d c/],     [qw/dis b/],
  [qw/e ais/],   [qw/f a/],     [qw/fis gis/], [qw/g g/],
  [qw/gis fis/], [qw/a f/],     [qw/ais e/],   [qw/b dis/]
  ) {
  is( $n->parse( $ref->[0] )->invert('cis')->as_string,
    $ref->[1], "e-axis inversion on " . $ref->[0] );
}

is( $n->set_value(0)->transpose(1)->get_value, 1, "check transpose" );

my $na = Music::LilyPond::Scale::Chromatic->new('c');
my $nb = $na->clone;
isa_ok( $nb, 'Music::LilyPond::Scale::Chromatic' );

$nb->parse('aes');
is( $na->as_string, 'c', 'check original after clone()' );

$na->parse('c');
is( $nb->as_string, 'aes', 'check clone after clone()' );

# Accidental & defaults thereof testing
{
  is( Music::LilyPond::Scale::Chromatic->get_default_accidental,
    undef, 'check default accidental setting' );

  is(
    Music::LilyPond::Scale::Chromatic->new('c')->transpose(1)->as_string,
    'cis',
    'check default accidental handling for neutrals'
  );
  is( Music::LilyPond::Scale::Chromatic->new('cis')->transpose(2)->as_string,
    'dis', 'check default accidental handling for sharps' );
  is( Music::LilyPond::Scale::Chromatic->new('ces')->transpose(-1)->as_string,
    'bes', 'check default accidental handling for flats' );

  for my $ref ( [ qw/is 1/, [qw/cis dis ais/] ],
    [ qw/es -1/, [qw/des ees bes/] ] ) {
    Music::LilyPond::Scale::Chromatic->set_default_accidental( $ref->[0] );

    is( Music::LilyPond::Scale::Chromatic->get_default_accidental,
      $ref->[1], "check accidental setting for " . $ref->[0] );

    is( Music::LilyPond::Scale::Chromatic->new('c')->transpose(1)->as_string,
      $ref->[2][0], 'check default accidental handling for neutrals' );
    is(
      Music::LilyPond::Scale::Chromatic->new('cis')->transpose(2)->as_string,
      $ref->[2][1], 'check default accidental handling for sharps'
    );
    is(
      Music::LilyPond::Scale::Chromatic->new('ces')->transpose(-1)->as_string,
      $ref->[2][2], 'check default accidental handling for flats'
    );
  }

  Music::LilyPond::Scale::Chromatic->unset_default_accidental;
  is( Music::LilyPond::Scale::Chromatic->get_default_accidental,
    undef, 'check default accidental setting' );
}
