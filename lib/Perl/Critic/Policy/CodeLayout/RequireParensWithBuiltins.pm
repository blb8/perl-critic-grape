package Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/ :severities :data_conversion :classification :language /;
use base 'Perl::Critic::Policy';

our $VERSION = '0.1.1';

Readonly::Scalar my $DESC  => q{Builtin function called without parentheses};
Readonly::Scalar my $EXPL  => [ 13 ];

# One interpretation suggests that parentheses aren't needed when the function is followed
# by an operator of lower precedence.  Since thi is less consistent, it has been removed
# from the current implementation.
# Readonly::Scalar my $lcprec => precedence_of(q{-e});

Readonly::Array my @NAMED_UNARY_OPS => qw(
	chdir
	chroot
	cos
	glob
	gmtime
	hex
	int
	lc
	lcfirst
	length
	localtime
	log
	lstat
	oct
	ord
	quotemeta
	rand
	readlink
	rmdir
	sin
	sleep
	sqrt
	srand
	stat
	uc
	ucfirst
	umask
);
Readonly::Hash my %NAMED_UNARY_OPS => hashify( @NAMED_UNARY_OPS );
Readonly::Array my @ALLOW => qw(
	alarm
	caller
	defined
	delete
	do
	eval
	exists
	exit
	getgrp
	gethostbyname
	getnetbyname
	getprotobyname
	lock
	my
	ref
	require
	return
	scalar
	undef
);
Readonly::Hash my %ALLOW => hashify( @ALLOW );

####-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'operators',
			description    => 'The unary operators that should be restricted.',
			default_string => join(' ',grep {!exists($ALLOW{$_})} @NAMED_UNARY_OPS),
			behavior       => 'string list',
		},
		{
			name           => 'allow',
			description    => 'The unary operators that should be ignored.',
			default_string => join(' ', @ALLOW),
			behavior       => 'string list',
		},
	);
}

sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core cosmetic ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
	my ($self,$elem,undef)=@_;
	if(!is_function_call($elem))                        { return }
	if(!exists($$self{_operators}{ $elem->content() })) { return }
	if(exists($$self{_allow}{ $elem->content() }))      { return }

	my $sibling=$elem->snext_sibling();
	if(!$sibling||!$sibling->isa('PPI::Structure::List')) { return $self->violation(sprintf("$DESC (%s)",$elem->content()),$EXPL,$elem) }
	return;
}

#-----------------------------------------------------------------------------

1;

__END__


=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins - Write C<lc($x // "Default")> instead of C<lc $x // "Default">.

=head1 DESCRIPTION

String folding is often used in map lookups where missing parentheses may not provide the expected behavior

	$LOOKUP{ lc $name // 'Default' }
	$LOOKUP{ lc( $name // 'Default' ) }

When C<$name> is undefined, the first form will lookup the value for C<""> (the empty string) and throw warnings from the C<lc> call.  The second form will lookup the value for C<"default">.  As an alternative approach

	$LOOKUP{ lc($name) || 'Default' }

will lookup the value for C<"default"> when C<$name> is undefined, but will still throw warnings from C<lc>.

=head1 CONFIGURATION

The named unary operators checked by the policy can be listed explicitly.

	[CodeLayout::RequireParensWithBuiltins]
	operators = lc lcfirst uc ucfirst

The default list includes most string and mathematical operators, but excludes certain system calls and block operators.  Specific named operators can be excluded:

	[CodeLayout::RequireParensWithBuiltins]
	allow = sqrt

=head1 NOTES

While coding with parentheses can sometimes lead to verbose constructs, a single case without parentheses can lead to invalid data in processing and results.  For these functions, the lack of parentheses causes ambiguity so they can be considered F<necessary>.  Code maintainability must also support quick insert of defaults and handling of warnings for undefined values, so calls without those mechanisms are likely incorrect F<from the start>.

=head1 BUGS

It's possible that some mathematical functions are more natural without parentheses even when followed by lower-precedence operators.  The current policy makes no special exemptions for different precedence interpretations for different functions.

=cut
