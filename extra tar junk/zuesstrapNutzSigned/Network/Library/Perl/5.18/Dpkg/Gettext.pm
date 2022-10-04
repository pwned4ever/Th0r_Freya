# Copied from /usr/share/perl5/Debconf/Gettext.pm
#
# Copyright © 2000 Joey Hess <joeyh@debian.org>
# Copyright © 2007, 2009-2010, 2012-2015 Guillem Jover <guillem@debian.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHORS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

package Dpkg::Gettext;

use strict;
use warnings;

our $VERSION = '1.02';
our @EXPORT = qw(
    textdomain
    ngettext
    g_
    P_
    N_
    _g
);

use Exporter qw(import);

=encoding utf8

=head1 NAME

Dpkg::Gettext - convenience wrapper around Locale::gettext

=head1 DESCRIPTION

The Dpkg::Gettext module is a convenience wrapper over the Locale::gettext
module, to guarantee we always have working gettext functions, and to add
some commonly used aliases.

=head1 VARIABLES

=over 4

=item $Dpkg::Gettext::DEFAULT_TEXT_DOMAIN

Specifies the default text domain name to be used with the short function
aliases. This is intended to be used by the Dpkg modules, so that they
can produce localized messages even when the calling program has set the
current domain with textdomain(). If you would like to use the aliases
for your own modules, you might want to set this variable to undef, or
to another domain, but then the Dpkg modules will not produce localized
messages.

=back

=cut

our $DEFAULT_TEXT_DOMAIN = 'dpkg-dev';

=head1 FUNCTIONS

=over 4

=item $trans = g_($msgid)

Calls dgettext() on the $msgid and returns its translation for the current
locale. If dgettext() is not available, simply returns $msgid.

=item $trans = C_($msgctxt, $msgid)

Calls dgettext() on the $msgid and returns its translation for the specific
$msgctxt supplied. If dgettext() is not available, simply returns $msgid.

=item $trans = P_($msgid, $msgid_plural, $n)

Calls dngettext(), returning the correct translation for the plural form
dependent on $n. If dngettext() is not available, returns $msgid if $n is 1
or $msgid_plural otherwise.

=cut

use constant GETTEXT_CONTEXT_GLUE => "\004";

BEGIN {
    eval q{
        pop @INC if $INC[-1] eq '.';
        use Locale::gettext;
    };
    if ($@) {
        eval q{
            sub g_ {
                return shift;
            }
            sub textdomain {
            }
            sub ngettext {
                my ($msgid, $msgid_plural, $n) = @_;
                if ($n == 1) {
                    return $msgid;
                } else {
                    return $msgid_plural;
                }
            }
            sub C_ {
                my ($msgctxt, $msgid) = @_;
                return $msgid;
            }
            sub P_ {
                return ngettext(@_);
            }
        };
    } else {
        eval q{
            sub g_ {
                return dgettext($DEFAULT_TEXT_DOMAIN, shift);
            }
            sub C_ {
                my ($msgctxt, $msgid) = @_;
                return dgettext($DEFAULT_TEXT_DOMAIN,
                                $msgctxt . GETTEXT_CONTEXT_GLUE . $msgid);
            }
            sub P_ {
                return dngettext($DEFAULT_TEXT_DOMAIN, @_);
            }
        };
    }
}

=item $msgid = N_($msgid)

A pseudo function that servers as a marked for automated extraction of
messages, but does not call gettext(). The run-time translation is done
at a different place in the code.

=back

=cut

sub N_
{
    my $msgid = shift;
    return $msgid;
}

# XXX: Backwards compatibility, to be removed on VERSION 2.00.
sub _g ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
{
    my $msgid = shift;

    warnings::warnif('deprecated',
                     'obsolete _g() function, please use g_() instead');

    return g_($msgid);
}

=head1 CHANGES

=head2 Version 1.02 (dpkg 1.18.3)

New function: N_().

=head2 Version 1.01 (dpkg 1.18.0)

Now the short aliases (g_ and P_) will call domain aware functions with
$DEFAULT_TEXT_DOMAIN.

New functions: g_(), C_().

Deprecated function: _g().

=head2 Version 1.00 (dpkg 1.15.6)

Mark the module as public.

=cut

1;
