# Copyright © 2013, 2015 Guillem Jover <guillem@debian.org>
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

package Dpkg::Util;

use strict;
use warnings;

our $VERSION = '0.01';
our @EXPORT_OK = qw(
    any
    none
);
our %EXPORT_TAGS = (
    list => [ qw(any none) ],
);

use Exporter qw(import);

# XXX: Ideally we would use List::MoreUtils, but that's not a core module,
# so to avoid the additional dependency we'll make do with the following
# trivial reimplementations.
#
# These got added to List::Util 1.33, which got merged into perl 5.20.0,
# once that is in Debian oldstable we can switch to that core module.

sub any(&@) {
    my $code = shift;

    foreach (@_) {
        return 1 if $code->();
    }

    return 0;
}

sub none(&@) {
    my $code = shift;

    foreach (@_) {
        return 0 if $code->();
    }

    return 1;
}

1;
