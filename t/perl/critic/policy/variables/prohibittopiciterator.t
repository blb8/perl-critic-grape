#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>2;

my $failure=qr/use named loop control/;

subtest 'Invalid loop control'=>sub {
	plan tests=>9;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitTopicIterator');
	ok(join('',map {$_->get_themes()} $critic->policies()),'themes');
	foreach my $code (
		q|foreach ($_=7;;) { ... }|,
		q|foreach (0..3) { ... }|,
		q|for($_=7;;) { ... }|,
		q|for(0..3) { ... }|,
		q|foreach $_ (0..3) { ... }|,
		q|for $_ (0..3) { ... }|,
		q|if($_=shift(A)) { ... }|,
		q|while($_=shift(A)) { ... }|,
		# ------------------------------ working to here
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

subtest 'Valid loop control'=>sub {
	plan tests=>15;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitTopicIterator');
	ok(join('',map {$_->get_themes()} $critic->policies()),'themes');
	foreach my $code (
		q|foreach (my $i=7;;) { ... }|,
		q|foreach my $i (0..3) { ... }|,
		q|for(my $i=7;;) { ... }|,
		q|for my $i (0..3) { ... }|,
		q|foreach my $i (0..3) { ... }|,
		q|for my $i (0..3) { ... }|,
		q|foreach ($i=7;;) { ... }|,
		q|foreach $i (0..3) { ... }|,
		q|for($i=7;;) { ... }|,
		q|for $i (0..3) { ... }|,
		q|foreach $i (0..3) { ... }|,
		q|for $i (0..3) { ... }|,
		q|if(my $i=shift(A)) { ... }|,
		q|while(my $i=shift(A)) { ... }|,
		# ------------------------------ working to here
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

