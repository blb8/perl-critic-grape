#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>2;

my $failure=qr/Builtin.*without parentheses/;

subtest 'Valid cases'=>sub {
	plan tests=>8;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins',-params=>{allow=>'rand srand'});
	foreach my $valid (
		['Fallback or',     'my $x=lc("hi"||"bye")'],
		['Undefined or',    'my $x=uc("hi"//"bye")'],
		['lt',              'my $x=lc("hi") lt lc("bye")'],
		['cmp',             'my $x=lc("hi") cmp lc("bye")'],
		['numeric <',       'my $x=int(5) < int(7)'],
		['not mandatory',   'my $x=lc("hi");'],
		['not builtin',     'my $x=function "hi";'],
		['allowed rand',    'my $x=rand 5;'],
	) {
		is_deeply([$critic->critique(\$$valid[1])],[],$$valid[0]);
	}
};

subtest 'Invalid cases'=>sub {
	plan tests=>10;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins');
	foreach my $invalid (
		['Standalone',      'my $x=lc "hi";'],
		['Fallback or',     'my $x=lc "hi"||"bye"'],
		['Undefined or',    'my $x=uc "hi"//"bye"'],
		['lt',              'my $x=lc "hi" lt lc "bye"'],
		['cmp',             'my $x=lc "hi" cmp lc "bye"'],
		['concat',          'my $x=lc "hi" . "bye"'],
		['numeric <',       'my $x=int 5 < int 7'],
		['topic input',     'my $x=rand'],
		['topic input;',    'my $x=rand;'],
		['topic input+',    'my $x=rand+5;'],
	) {
		like(($critic->critique(\$$invalid[1]))[0],$failure,$$invalid[0]);
	}
};

