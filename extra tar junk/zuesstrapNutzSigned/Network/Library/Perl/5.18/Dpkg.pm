# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Dpkg;

=encoding utf8

=head1 NAME

Dpkg - module with core variables

=head1 DESCRIPTION

The Dpkg module provides a set of variables with information concerning
this system installation.

=cut

use strict;
use warnings;

our $VERSION = '1.03';
our @EXPORT_OK = qw(
    $PROGNAME
    $PROGVERSION
    $PROGMAKE
    $PROGTAR
    $PROGPATCH
    $CONFDIR
    $ADMINDIR
    $LIBDIR
    $DATADIR
);
our @EXPORT = qw(
    $version
    $progname
    $admindir
    $dpkglibdir
    $pkgdatadir
);

use Exporter qw(import);

=head1 VARIABLES

=over 4

=item $Dpkg::PROGNAME

Contains the name of the current program.

=item $Dpkg::PROGVERSION

Contains the version of the dpkg suite.

=item $Dpkg::PROGMAKE

Contains the name of the system GNU make program.

=item $Dpkg::PROGTAR

Contains the name of the system GNU tar program.

=item $Dpkg::PROGPATCH

Contains the name of the system GNU patch program (or another implementation
that is directory traversal resistant).

=item $Dpkg::CONFDIR

Contains the path to the dpkg system configuration directory.

=item $Dpkg::ADMINDIR

Contains the path to the dpkg database directory.

=item $Dpkg::LIBDIR

Contains the path to the dpkg methods and plugins directory.

=item $Dpkg::DATADIR

Contains the path to the dpkg architecture tables directory.

=back

=cut

our ($PROGNAME) = $0 =~ m{(?:.*/)?([^/]*)};

# The following lines are automatically fixed at install time
our $PROGVERSION = '1.18.25';
our $PROGMAKE = '/Applications/Xcode.app/Contents/Developer/usr/bin/make';
our $PROGTAR = 'tar';
our $PROGPATCH = 'gpatch';

our $CONFDIR = '/etc/dpkg';
our $ADMINDIR = '/var/lib/dpkg';
our $LIBDIR = '/usr/libexec/dpkg';
our $DATADIR = '/usr/share/dpkg';

$DATADIR = $ENV{DPKG_DATADIR} if defined $ENV{DPKG_DATADIR};

# XXX: Backwards compatibility, to be removed on VERSION 2.00.
## no critic (Variables::ProhibitPackageVars)
our $version = $PROGVERSION;
our $admindir = $ADMINDIR;
our $dpkglibdir = $LIBDIR;
our $pkgdatadir = $DATADIR;
## use critic

=head1 CHANGES

=head2 Version 1.03 (dpkg 1.18.24)

New variable: $PROGPATCH.

=head2 Version 1.02 (dpkg 1.18.11)

New variable: $PROGTAR, $PROGMAKE.

=head2 Version 1.01 (dpkg 1.17.0)

New variables: $PROGNAME, $PROGVERSION, $CONFDIR, $ADMINDIR, $LIBDIR and
$DATADIR.

Deprecated variables: $version, $admindir, $dpkglibdir and $pkgdatadir.

=head2 Version 1.00 (dpkg 1.15.6)

Mark the module as public.

=cut

1;
