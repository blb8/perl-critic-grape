#!/usr/bin/perl

use 5.020001; # postfix dereferencing operators here
use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>2;

my $failure=qr/Only use arrows for methods/;

subtest 'Valid cases'=>sub {
	plan tests=>8;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils');
	#
	foreach my $code (
		q|my $y=$$x;|,
		q|my $y=$$x[0];|,
		q|my $y=$$x{hi};|,
		q|my $x=&$f(1);|,
		q|my @A=@$x;|,
		q|my %H=%$x;|,
		q|my $y=$x->method;|,
		q|my $y=$x->method();|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Invalid cases'=>sub {
	plan tests=>5;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils');
	#
	foreach my $code (
		q|my $y=$x->[0];|,
		q|my $y=$x->{hi};|,
		q|my $x=$f->(1);|,
		q|my @A=$x->@*;|,
		q|my %H=$x->%*;|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

