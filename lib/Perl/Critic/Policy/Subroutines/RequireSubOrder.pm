package Perl::Critic::Policy::Subroutines::RequireSubOrder;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities :classification/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.0.8';

Readonly::Scalar my $DESC  => q{Place subroutines in dependency order};
Readonly::Scalar my $EXPL  => undef;

#-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'all',
			description    => 'Report all names a subroutine must appear after.',
			default_string => '0',
			behavior       => 'boolean',
		},
		{
			name           => 'backwards',
			description    => 'Expect dependencies to follow their callers.',
			default_string => '0',
			behavior       => 'boolean',
		},
	);
}

sub applies_to           { return qw/PPI::Statement::Sub/ }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw/cosmetic/ }

#-----------------------------------------------------------------------------

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

sub _loc { my ($node)=@_; return join(' ',map {$_//'U'} @{$node->location()}) }

sub _blockcalls {
	my ($self,$package,$doc)=@_;
	if(!$doc) { return }
	my %res;
	foreach my $word (grep {is_function_call($_)&&!is_perl_builtin($_)} @{$doc->find('PPI::Token::Word')||[]}) {
		my $name=$word->content();
		if($name=~/^(.*)::([^:]+)$/) {
			if($1 eq $package) { $res{$2}=undef }
		}
		elsif($name!~/::/) { $res{$name}=undef }
	}
	return keys(%res);
}

# The Perl compiler fully scans the document for subroutine names, permitting out-of-order
# dependencies, so it's necessary here to fully map all subroutine names, and their packages, to
# determine if dependencies are declared within the document.  Anything encountered but not
# declared is imported, via 'use' or 'do', and assumed declared prior to use.  If the author
# calls 'do' too late, that's a runtime error not detected here.  Likewise, anonymous subs are
# ignored since standard variable scoping controls their availability.

my $cachekey;
sub initialize_if_enabled {
	my ($self,$config)=@_;
	my $name='__REQUIRESUBORDER__';
	my $suffix=int(rand(1e9));
	my $retry=3;
	while($retry&&exists($$self{"$name$suffix"})) { $suffix=int(rand(1e9)); $retry-- }
	if(exists($$self{"$name$suffix"})) { warn 'RequireSubOrder unable to build subroutine cache' }
	else {
		$cachekey="$name$suffix";
		$$self{$cachekey}={cache=>{},recent=>[]};
	}
	return 1;
}

sub prepare_to_scan_document {
	my ($self,$doc,$package)=@_;
	if(!$cachekey) { return 0 }
	%{$$self{$cachekey}}=();
	$package//='main';
	foreach my $node ($doc->children()) {
		if($node->isa('PPI::Statement::Package')) { $package=$node->namespace() }
		elsif($node->isa('PPI::Statement::Sub')) {
			my $loc=_loc($node);
			$$self{$cachekey}{sub}{$node->name()}//={};
			my $csub=$$self{$cachekey}{sub}{$node->name()};
			if(exists($$csub{$loc})) { warn "A declaration of subroutine @{[$node->name()]} has already been encountered at this location" }
			$$csub{$loc}={
				package=>$package,
				node=>$node,
				name=>$node->name(),
				loc=>$node->location(),
				calls=>[$self->_blockcalls($package,$node->block())],
			};
			$$self{$cachekey}{package}{$package}{$node->name()}{$loc}=$$csub{$loc};
			#
			# there might be some issue if $node->forward() is true
		}
		elsif($node->isa('PPI::Statement::Compound')||$node->isa('PPI::Structure::Block')) { $self->prepare_to_scan_document($node,$package) }
		# else do nothing
	}
	return 1;
}

sub _cmploc {
	my ($X,$Y)=@_;
	if($$X[0]<$$Y[0]) { return -1 }
	if($$X[0]>$$Y[0]) { return +1 }
	if($$X[1]<$$Y[1]) { return -1 }
	if($$X[1]>$$Y[1]) { return +1 }
	return 0;
}

sub _sortloc {
	my (@items)=@_;
	return sort {_cmploc($$a{loc},$$b{loc})} @items;
}

sub _depends {
	my ($self,$pkg,$name,$dep)=@_;
	foreach my $definition (values %{$$self{$cachekey}{package}{$pkg}{$name}}) {
		foreach my $name (@{$$definition{calls}}) {
			if($name eq $dep) { return 1 }
		}
	}
	return 0;
}

sub violates {
	my ($self,$elem,undef)=@_;
	my $sub=$$self{$cachekey}{sub}{$elem->name()}{_loc($elem)};
	if(!$sub) { return }
	#
	my @dependencies;
	foreach my $dep (@{$$sub{calls}}) {
		my @deps=_sortloc(values(%{$$self{$cachekey}{package}{$$sub{package}}{$dep}}));
		if(@deps) {
			if($$self{_backwards} && (_cmploc($deps[-1]{loc},$elem->location())<0)){ push @dependencies,$deps[0] }
			elsif                    (_cmploc($deps[0]{loc}, $elem->location())>0) { push @dependencies,$deps[-1] }
		}
	}
	if(@dependencies) {
		@dependencies=map {+{cyclic=>($self->_depends(@$_{qw/package name/},$$sub{name})?' (cyclic)':''),
			package=>$$_{package},name=>$$_{name}}} _sortloc(@dependencies);
		if(!$$self{_all}) { @dependencies=$dependencies[-1] }
		@dependencies=join(q{, },map {sprintf("'%s::%s'%s",@$_{qw/package name cyclic/})} @dependencies);
		if($$self{_backwards}) { return $self->invalid($elem,sprintf("move %s after '%s::%s'",$dependencies[0],$$sub{package},$elem->name())) }
		else                   { return $self->invalid($elem,sprintf("move '%s::%s' after %s",$$sub{package},$elem->name(),$dependencies[0])) }
	}
	return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireSubOrder - Place subroutines in dependency order

=head1 DESCRIPTION

not here yet

=head2 Motivation

not here yet

=head2 Supported behaviors

Ignores undeclared functions, which are assumed to be imported.

Supports inline C<package> declarations.

Supports blocked C<package> declarations.

Supports package-prefixed calls.

Supports forward declarations.

Reports cycles.

=head1 CONFIGURATION

=head2 All dependencies

By default, only the latest dependency is given for a misplaced subroutine to appear after.  To report all names a subroutine must appear after:

  [Subroutines::RequireSubOrder]
  all = 1

=head2 Backwards ordering

The default ordering is topological for the reasons provided above.  To instead apply a model where "all the dependent calls made by the subroutine appear I<after>":

  [Subroutines::RequireSubOrder]
  backwards = 1

=head2 Todo

Perhaps consider alphabetical ordering within the same group.

=head1 BUGS

Nothing here yet.

=head1 SEE ALSO

Nothing here yet.

=cut
