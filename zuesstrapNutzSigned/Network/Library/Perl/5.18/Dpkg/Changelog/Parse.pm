# Copyright © 2005, 2007 Frank Lichtenheld <frank@lichtenheld.de>
# Copyright © 2009       Raphaël Hertzog <hertzog@debian.org>
# Copyright © 2010, 2012-2015 Guillem Jover <guillem@debian.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Dpkg::Changelog::Parse - generic changelog parser for dpkg-parsechangelog

=head1 DESCRIPTION

This module provides a set of functions which reproduce all the features
of dpkg-parsechangelog.

=cut

package Dpkg::Changelog::Parse;

use strict;
use warnings;

our $VERSION = '1.02';
our @EXPORT = qw(
    changelog_parse_debian
    changelog_parse_plugin
    changelog_parse
);

use Exporter qw(import);

use Dpkg ();
use Dpkg::Util qw(none);
use Dpkg::Gettext;
use Dpkg::ErrorHandling;
use Dpkg::Control::Changelog;

sub _changelog_detect_format {
    my $file = shift;
    my $format = 'debian';

    # Extract the format from the changelog file if possible
    if ($file ne '-') {
        local $_;

        open my $format_fh, '-|', 'tail', '-n', '40', $file
            or syserr(g_('cannot create pipe for %s'), 'tail');
        while (<$format_fh>) {
            $format = $1 if m/\schangelog-format:\s+([0-9a-z]+)\W/;
        }
        close $format_fh or subprocerr(g_('tail of %s'), $file);
    }

    return $format;
}

=head1 FUNCTIONS

=over 4

=item $fields = changelog_parse_debian(%opt)

This function is deprecated, use changelog_parse() instead, with the changelog
format set to "debian".

=cut

sub changelog_parse_debian {
    my (%options) = @_;

    warnings::warnif('deprecated',
                     'deprecated function changelog_parse_debian, use changelog_parse instead');

    # Force the plugin to be debian.
    $options{changelogformat} = 'debian';

    return _changelog_parse(%options);
}

=item $fields = changelog_parse_plugin(%opt)

This function is deprecated, use changelog_parse() instead.

=cut

sub changelog_parse_plugin {
    my (%options) = @_;

    warnings::warnif('deprecated',
                     'deprecated function changelog_parse_plugin, use changelog_parse instead');

    return _changelog_parse(%options);
}

=item $fields = changelog_parse(%opt)

This function will parse a changelog. In list context, it returns as many
Dpkg::Control objects as the parser did create. In scalar context, it will
return only the first one. If the parser did not return any data, it will
return an empty list in list context or undef on scalar context. If the
parser failed, it will die.

The changelog file that is parsed is F<debian/changelog> by default but it
can be overridden with $opt{file}. The default output format is "dpkg" but
it can be overridden with $opt{format}.

The parsing itself is done by a parser module (searched in the standard
perl library directories. That module is named according to the format that
it is able to parse, with the name capitalized. By default it is either
Dpkg::Changelog::Debian (from the "debian" format) or the format name looked
up in the 40 last lines of the changelog itself (extracted with this perl
regular expression "\schangelog-format:\s+([0-9a-z]+)\W"). But it can be
overridden with $opt{changelogformat}.

All the other keys in %opt are forwarded to the parser module constructor.

=cut

sub _changelog_parse {
    my (%options) = @_;

    # Setup and sanity checks.
    if (exists $options{libdir}) {
        warnings::warnif('deprecated',
                         'obsolete libdir option, changelog parsers are now perl modules');
    }

    $options{file} //= 'debian/changelog';
    $options{label} //= $options{file};
    $options{changelogformat} //= _changelog_detect_format($options{file});
    $options{format} //= 'dpkg';

    my @range_opts = qw(since until from to offset count all);
    $options{all} = 1 if exists $options{all};
    if (none { defined $options{$_} } @range_opts) {
        $options{count} = 1;
    }
    my $range;
    foreach my $opt (@range_opts) {
        $range->{$opt} = $options{$opt} if exists $options{$opt};
    }

    # Find the right changelog parser.
    my $format = ucfirst lc $options{changelogformat};
    my $changes;
    eval qq{
        pop \@INC if \$INC[-1] eq '.';
        require Dpkg::Changelog::$format;
        \$changes = Dpkg::Changelog::$format->new();
    };
    error(g_('changelog format %s is unknown: %s'), $format, $@) if $@;
    $changes->set_options(reportfile => $options{label}, range => $range);

    # Load and parse the changelog.
    $changes->load($options{file})
        or error(g_('fatal error occurred while parsing %s'), $options{file});

    # Get the output into several Dpkg::Control objects.
    my @res;
    if ($options{format} eq 'dpkg') {
        push @res, $changes->format_range('dpkg', $range);
    } elsif ($options{format} eq 'rfc822') {
        push @res, $changes->format_range('rfc822', $range);
    } else {
        error(g_('unknown output format %s'), $options{format});
    }

    if (wantarray) {
        return @res;
    } else {
        return $res[0] if @res;
        return;
    }
}

sub changelog_parse {
    my (%options) = @_;

    if (exists $options{forceplugin}) {
        warnings::warnif('deprecated', 'obsolete forceplugin option');
    }

    return _changelog_parse(%options);
}

=back

=head1 CHANGES

=head2 Version 1.02 (dpkg 1.18.8)

Deprecated functions: changelog_parse_debian(), changelog_parse_plugin().

Obsolete options: $forceplugin, $libdir.

=head2 Version 1.01 (dpkg 1.18.2)

New functions: changelog_parse_debian(), changelog_parse_plugin().

=head2 Version 1.00 (dpkg 1.15.6)

Mark the module as public.

=cut

1;
