# Copyright © 2016 Guillem Jover <guillem@debian.org>
#
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

package Dpkg::Build::Info;

use strict;
use warnings;

our $VERSION = '1.00';
our @EXPORT_OK = qw(
    get_build_env_whitelist
);

use Exporter qw(import);

=encoding utf8

=head1 NAME

Dpkg::Build::Info - handle build information

=head1 DESCRIPTION

The Dpkg::Build::Info module provides functions to handle the build
information.

=head1 FUNCTIONS

=over 4

=item @envvars = get_build_env_whitelist()

Get an array with the whitelist of environment variables that can affect
the build, but are still not privacy revealing.

=cut

my @env_whitelist = (
    # Toolchain.
    qw(CC CPP CXX OBJC OBJCXX PC FC M2C AS LD AR RANLIB MAKE AWK LEX YACC),
    # Toolchain flags.
    qw(CFLAGS CPPFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS GCJFLAGS FFLAGS
       LDFLAGS ARFLAGS MAKEFLAGS),
    # Dynamic linker, see ld(1).
    qw(LD_LIBRARY_PATH),
    # Locale, see locale(1).
    qw(LANG LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY
       LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
       LC_IDENTIFICATION),
    # Build flags, see dpkg-buildpackage(1).
    qw(DEB_BUILD_OPTIONS DEB_BUILD_PROFILES),
    # DEB_flag_{SET,STRIP,APPEND,PREPEND} will be recorded after being merged
    # with system config and user config.
    # See deb-vendor(1).
    qw(DEB_VENDOR),
    # See dpkg(1).
    qw(DPKG_ROOT DPKG_ADMINDIR),
    # See dpkg-architecture(1).
    qw(DPKG_DATADIR),
    # See Dpkg::Vendor(3).
    qw(DPKG_ORIGINS_DIR),
    # See dpkg-gensymbols(1).
    qw(DPKG_GENSYMBOLS_CHECK_LEVEL),
    # See <https://reproducible-builds.org/specs/source-date-epoch>.
    qw(SOURCE_DATE_EPOCH),
);

sub get_build_env_whitelist {
    return @env_whitelist;
}

=back

=head1 CHANGES

=head2 Version 1.00 (dpkg 1.18.14)

Mark the module as public.

=cut

1;
