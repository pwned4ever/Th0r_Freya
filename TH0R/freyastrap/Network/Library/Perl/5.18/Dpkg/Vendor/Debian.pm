# Copyright © 2009-2011 Raphaël Hertzog <hertzog@debian.org>
# Copyright © 2009, 2011-2017 Guillem Jover <guillem@debian.org>
#
# Hardening build flags handling derived from work of:
# Copyright © 2009-2011 Kees Cook <kees@debian.org>
# Copyright © 2007-2008 Canonical, Ltd.
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

package Dpkg::Vendor::Debian;

use strict;
use warnings;

our $VERSION = '0.01';

use Dpkg;
use Dpkg::Gettext;
use Dpkg::ErrorHandling;
use Dpkg::Control::Types;
use Dpkg::BuildOptions;
use Dpkg::Arch qw(get_host_arch debarch_to_debtuple);

use parent qw(Dpkg::Vendor::Default);

=encoding utf8

=head1 NAME

Dpkg::Vendor::Debian - Debian vendor object

=head1 DESCRIPTION

This vendor object customizes the behaviour of dpkg scripts for Debian
specific behavior and policies.

=cut

sub run_hook {
    my ($self, $hook, @params) = @_;

    if ($hook eq 'package-keyrings') {
        return ('/usr/share/keyrings/debian-keyring.gpg',
                '/usr/share/keyrings/debian-maintainers.gpg');
    } elsif ($hook eq 'keyrings') {
        warnings::warnif('deprecated', 'deprecated keyrings vendor hook');
        return $self->run_hook('package-keyrings', @params);
    } elsif ($hook eq 'archive-keyrings') {
        return ('/usr/share/keyrings/debian-archive-keyring.gpg');
    } elsif ($hook eq 'archive-keyrings-historic') {
        return ('/usr/share/keyrings/debian-archive-removed-keys.gpg');
    } elsif ($hook eq 'builtin-build-depends') {
        return qw(build-essential:native);
    } elsif ($hook eq 'builtin-build-conflicts') {
        return ();
    } elsif ($hook eq 'register-custom-fields') {
    } elsif ($hook eq 'extend-patch-header') {
        my ($textref, $ch_info) = @params;
	if ($ch_info->{'Closes'}) {
	    foreach my $bug (split(/\s+/, $ch_info->{'Closes'})) {
		$$textref .= "Bug-Debian: https://bugs.debian.org/$bug\n";
	    }
	}

	# XXX: Layer violation...
	require Dpkg::Vendor::Ubuntu;
	my $b = Dpkg::Vendor::Ubuntu::find_launchpad_closes($ch_info->{'Changes'});
	foreach my $bug (@$b) {
	    $$textref .= "Bug-Ubuntu: https://bugs.launchpad.net/bugs/$bug\n";
	}
    } elsif ($hook eq 'update-buildflags') {
	$self->_add_qa_flags(@params);
	$self->_add_reproducible_flags(@params);
	$self->_add_sanitize_flags(@params);
	$self->_add_hardening_flags(@params);
    } elsif ($hook eq 'builtin-system-build-paths') {
        return qw(/build/);
    } else {
        return $self->SUPER::run_hook($hook, @params);
    }
}

sub _parse_feature_area {
    my ($self, $area, $use_feature) = @_;

    # Adjust features based on user or maintainer's desires.
    my $opts = Dpkg::BuildOptions->new(envvar => 'DEB_BUILD_OPTIONS');
    $opts->parse_features($area, $use_feature);
    $opts = Dpkg::BuildOptions->new(envvar => 'DEB_BUILD_MAINT_OPTIONS');
    $opts->parse_features($area, $use_feature);
}

sub _add_qa_flags {
    my ($self, $flags) = @_;

    # Default feature states.
    my %use_feature = (
        bug => 0,
        canary => 0,
    );

    # Adjust features based on user or maintainer's desires.
    $self->_parse_feature_area('qa', \%use_feature);

    # Warnings that detect actual bugs.
    if ($use_feature{bug}) {
        foreach my $warnflag (qw(array-bounds clobbered volatile-register-var
                                 implicit-function-declaration)) {
            $flags->append('CFLAGS', "-Werror=$warnflag");
            $flags->append('CXXFLAGS', "-Werror=$warnflag");
        }
    }

    # Inject dummy canary options to detect issues with build flag propagation.
    if ($use_feature{canary}) {
        require Digest::MD5;
        my $id = Digest::MD5::md5_hex(int rand 4096);

        foreach my $flag (qw(CPPFLAGS CFLAGS OBJCFLAGS CXXFLAGS OBJCXXFLAGS)) {
            $flags->append($flag, "-D__DEB_CANARY_${flag}_${id}__");
        }
        $flags->append('LDFLAGS', "-Wl,-z,deb-canary-${id}");
    }

    # Store the feature usage.
    while (my ($feature, $enabled) = each %use_feature) {
        $flags->set_feature('qa', $feature, $enabled);
    }
}

sub _add_reproducible_flags {
    my ($self, $flags) = @_;

    # Default feature states.
    my %use_feature = (
        timeless => 1,
        fixdebugpath => 1,
    );

    my $build_path;

    # Adjust features based on user or maintainer's desires.
    $self->_parse_feature_area('reproducible', \%use_feature);

    # Mask features that might have an unsafe usage.
    if ($use_feature{fixdebugpath}) {
        require Cwd;

        $build_path = $ENV{DEB_BUILD_PATH} || Cwd::cwd();

        # If we have any unsafe character in the path, disable the flag,
        # so that we do not need to worry about escaping the characters
        # on output.
        if ($build_path =~ m/[^-+:.0-9a-zA-Z~\/_]/) {
            $use_feature{fixdebugpath} = 0;
        }
    }

    # Warn when the __TIME__, __DATE__ and __TIMESTAMP__ macros are used.
    if ($use_feature{timeless}) {
       $flags->append('CPPFLAGS', '-Wdate-time');
    }

    # Avoid storing the build path in the debug symbols.
    if ($use_feature{fixdebugpath}) {
        my $map = '-fdebug-prefix-map=' . $build_path . '=.';
        $flags->append('CFLAGS', $map);
        $flags->append('CXXFLAGS', $map);
        $flags->append('OBJCFLAGS', $map);
        $flags->append('OBJCXXFLAGS', $map);
        $flags->append('FFLAGS', $map);
        $flags->append('FCFLAGS', $map);
        $flags->append('GCJFLAGS', $map);
    }

    # Store the feature usage.
    while (my ($feature, $enabled) = each %use_feature) {
       $flags->set_feature('reproducible', $feature, $enabled);
    }
}

sub _add_sanitize_flags {
    my ($self, $flags) = @_;

    # Default feature states.
    my %use_feature = (
        address => 0,
        thread => 0,
        leak => 0,
        undefined => 0,
    );

    # Adjust features based on user or maintainer's desires.
    $self->_parse_feature_area('sanitize', \%use_feature);

    # Handle logical feature interactions.
    if ($use_feature{address} and $use_feature{thread}) {
        # Disable the thread sanitizer when the address one is active, they
        # are mutually incompatible.
        $use_feature{thread} = 0;
    }
    if ($use_feature{address} or $use_feature{thread}) {
        # Disable leak sanitizer, it is implied by the address or thread ones.
        $use_feature{leak} = 0;
    }

    if ($use_feature{address}) {
        my $flag = '-fsanitize=address -fno-omit-frame-pointer';
        $flags->append('CFLAGS', $flag);
        $flags->append('CXXFLAGS', $flag);
        $flags->append('LDFLAGS', '-fsanitize=address');
    }

    if ($use_feature{thread}) {
        my $flag = '-fsanitize=thread';
        $flags->append('CFLAGS', $flag);
        $flags->append('CXXFLAGS', $flag);
        $flags->append('LDFLAGS', $flag);
    }

    if ($use_feature{leak}) {
        $flags->append('LDFLAGS', '-fsanitize=leak');
    }

    if ($use_feature{undefined}) {
        my $flag = '-fsanitize=undefined';
        $flags->append('CFLAGS', $flag);
        $flags->append('CXXFLAGS', $flag);
        $flags->append('LDFLAGS', $flag);
    }

    # Store the feature usage.
    while (my ($feature, $enabled) = each %use_feature) {
       $flags->set_feature('sanitize', $feature, $enabled);
    }
}

sub _add_hardening_flags {
    my ($self, $flags) = @_;
    my $arch = get_host_arch();
    my ($abi, $libc, $os, $cpu) = debarch_to_debtuple($arch);

    unless (defined $abi and defined $libc and defined $os and defined $cpu) {
        warning(g_("unknown host architecture '%s'"), $arch);
        ($abi, $os, $cpu) = ('', '', '');
    }

    # Default feature states.
    my %use_feature = (
	# XXX: This is set to undef so that we can cope with the brokenness
	# of gcc managing this feature builtin.
	pie => undef,
	stackprotector => 1,
	stackprotectorstrong => 1,
	fortify => 1,
	format => 1,
	relro => 1,
	bindnow => 0,
    );
    my %builtin_feature = (
        pie => 1,
    );

    my %builtin_pie_arch = map { $_ => 1 } qw(
        amd64 arm64 armel armhf i386 kfreebsd-amd64 kfreebsd-i386
        mips mipsel mips64el ppc64el s390x sparc sparc64
    );

    # Mask builtin features that are not enabled by default in the compiler.
    if (not exists $builtin_pie_arch{$arch}) {
        $builtin_feature{pie} = 0;
    }

    # Adjust features based on user or maintainer's desires.
    $self->_parse_feature_area('hardening', \%use_feature);

    # Mask features that are not available on certain architectures.
    if ($os !~ /^(?:linux|kfreebsd|knetbsd|hurd)$/ or
	$cpu =~ /^(?:hppa|avr32)$/) {
	# Disabled on non-(linux/kfreebsd/knetbsd/hurd).
	# Disabled on hppa, avr32
	#  (#574716).
	$use_feature{pie} = 0;
    }
    if ($cpu =~ /^(?:ia64|alpha|hppa|nios2)$/ or $arch eq 'arm') {
	# Stack protector disabled on ia64, alpha, hppa, nios2.
	#   "warning: -fstack-protector not supported for this target"
	# Stack protector disabled on arm (ok on armel).
	#   compiler supports it incorrectly (leads to SEGV)
	$use_feature{stackprotector} = 0;
    }
    if ($cpu =~ /^(?:ia64|hppa|avr32)$/) {
	# relro not implemented on ia64, hppa, avr32.
	$use_feature{relro} = 0;
    }

    # Mask features that might be influenced by other flags.
    if ($flags->{build_options}->has('noopt')) {
      # glibc 2.16 and later warn when using -O0 and _FORTIFY_SOURCE.
      $use_feature{fortify} = 0;
    }

    # Handle logical feature interactions.
    if ($use_feature{relro} == 0) {
	# Disable bindnow if relro is not enabled, since it has no
	# hardening ability without relro and may incur load penalties.
	$use_feature{bindnow} = 0;
    }
    if ($use_feature{stackprotector} == 0) {
	# Disable stackprotectorstrong if stackprotector is disabled.
	$use_feature{stackprotectorstrong} = 0;
    }

    # PIE
    if (defined $use_feature{pie} and $use_feature{pie} and
        not $builtin_feature{pie}) {
	my $flag = "-specs=$Dpkg::DATADIR/pie-compile.specs";
	$flags->append('CFLAGS', $flag);
	$flags->append('OBJCFLAGS',  $flag);
	$flags->append('OBJCXXFLAGS', $flag);
	$flags->append('FFLAGS', $flag);
	$flags->append('FCFLAGS', $flag);
	$flags->append('CXXFLAGS', $flag);
	$flags->append('GCJFLAGS', $flag);
	$flags->append('LDFLAGS', "-specs=$Dpkg::DATADIR/pie-link.specs");
    } elsif (defined $use_feature{pie} and not $use_feature{pie} and
             $builtin_feature{pie}) {
	my $flag = "-specs=$Dpkg::DATADIR/no-pie-compile.specs";
	$flags->append('CFLAGS', $flag);
	$flags->append('OBJCFLAGS',  $flag);
	$flags->append('OBJCXXFLAGS', $flag);
	$flags->append('FFLAGS', $flag);
	$flags->append('FCFLAGS', $flag);
	$flags->append('CXXFLAGS', $flag);
	$flags->append('GCJFLAGS', $flag);
	$flags->append('LDFLAGS', "-specs=$Dpkg::DATADIR/no-pie-link.specs");
    }

    # Stack protector
    if ($use_feature{stackprotectorstrong}) {
	my $flag = '-fstack-protector-strong';
	$flags->append('CFLAGS', $flag);
	$flags->append('OBJCFLAGS', $flag);
	$flags->append('OBJCXXFLAGS', $flag);
	$flags->append('FFLAGS', $flag);
	$flags->append('FCFLAGS', $flag);
	$flags->append('CXXFLAGS', $flag);
	$flags->append('GCJFLAGS', $flag);
    } elsif ($use_feature{stackprotector}) {
	my $flag = '-fstack-protector --param=ssp-buffer-size=4';
	$flags->append('CFLAGS', $flag);
	$flags->append('OBJCFLAGS', $flag);
	$flags->append('OBJCXXFLAGS', $flag);
	$flags->append('FFLAGS', $flag);
	$flags->append('FCFLAGS', $flag);
	$flags->append('CXXFLAGS', $flag);
	$flags->append('GCJFLAGS', $flag);
    }

    # Fortify Source
    if ($use_feature{fortify}) {
	$flags->append('CPPFLAGS', '-D_FORTIFY_SOURCE=2');
    }

    # Format Security
    if ($use_feature{format}) {
	my $flag = '-Wformat -Werror=format-security';
	$flags->append('CFLAGS', $flag);
	$flags->append('CXXFLAGS', $flag);
	$flags->append('OBJCFLAGS', $flag);
	$flags->append('OBJCXXFLAGS', $flag);
    }

    # Read-only Relocations
    if ($use_feature{relro}) {
	$flags->append('LDFLAGS', '-Wl,-z,relro');
    }

    # Bindnow
    if ($use_feature{bindnow}) {
	$flags->append('LDFLAGS', '-Wl,-z,now');
    }

    # Set used features to their builtin setting if unset.
    foreach my $feature (keys %builtin_feature) {
	$use_feature{$feature} //= $builtin_feature{$feature};
    }

    # Store the feature usage.
    while (my ($feature, $enabled) = each %use_feature) {
	$flags->set_feature('hardening', $feature, $enabled);
    }
}

=head1 CHANGES

=head2 Version 0.xx

This is a private module.

=cut

1;
