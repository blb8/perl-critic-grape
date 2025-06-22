#!/usr/bin/perl

use 5.020001; # postfix dereferencing operators here
use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>2;

my $failure=qr/Only use arrows for methods/;

subtest 'Valid cases'=>sub {
	plan tests=>21;
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
		q|print 'a',$$x;|,
		q|print 'a',$$x[0];|,
		q|print 'a',$$x{hi};|,
		q|print 'a',&$f(1);|,
		q|print 'a',@$x;|,
		q|print 'a',%$x;|,
		q|print 'a',$x->method;|,
		q|print 'a',$x->method();|,
		q|my $y=${$x};|,           # uhhgly, but not yet rejected
		q|my $y=${$x}[0];|,        # uhhgly, but not yet rejected
		q|my $y=${$x}{hi};|,       # uhhgly, but not yet rejected
		q|my @A=@{$x};|,           # uhhgly, but not yet rejected
		q|my %H=%{$x};|,           # uhhgly, but not yet rejected
		# q|print "a $$x b";|,     # not yet supported
		# q|print "a $$x[0] b";|,  # not yet supported
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Invalid cases'=>sub {
	plan tests=>10;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils');
	#
	foreach my $code (
		q|my $y=$x->[0];|,
		q|my $y=$x->{hi};|,
		q|my $x=$f->(1);|,
		q|my @A=$x->@*;|,
		q|my %H=$x->%*;|,
		q|print 'b',$x->[0];|,
		q|print 'b',$x->{hi};|,
		q|print 'b',$f->(1);|,
		q|print 'b',$x->@*;|,
		q|print 'b',$x->%*;|,
		# q|print "a $x->[0] b";|,  # not yet supported
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

