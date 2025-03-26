package Perl::Critic::Grape;

use strict;
use warnings;

our $VERSION='0.0.1';

1;

__END__

=head1 NAME

Perl::Critic::Grape - Additional Perl::Critic policies.

=head1 DESCRIPTION

Fruit is good for you!  Grapes can also be red or green, just like the status of your code based on these policies.

=head2 Policies

=over

=item L<CodeLayout::RequireParensWithBuiltins|Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins>

Built-in functions called without parentheses.

=item L<ControlStructures::ProhibitInlineDo|Perl::Critic::Policy::ControlStructures::ProhibitInlineDo>

Do not use inline do blocks.

=item L<References::ProhibitRefChecks|Perl::Critic::Policy::References::ProhibitRefChecks>

Do not perform manual ref checks.

=back

=cut
