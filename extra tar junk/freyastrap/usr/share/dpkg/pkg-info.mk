# Makefile snippet defining the following variables:
#
# DEB_SOURCE: the source package name
# DEB_VERSION: the full version of the package (epoch + upstream vers. + revision)
# DEB_VERSION_EPOCH_UPSTREAM: the package's version without the Debian revision
# DEB_VERSION_UPSTREAM_REVISION: the package's version without the Debian epoch
# DEB_VERSION_UPSTREAM: the package's upstream version
# DEB_DISTRIBUTION: the distribution(s) listed in the current entry of debian/changelog
#
# SOURCE_DATE_EPOCH: the source release date as seconds since the epoch, as
#   specified by <https://reproducible-builds.org/specs/source-date-epoch/>

dpkg_late_eval ?= $(or $(value DPKG_CACHE_$(1)),$(eval DPKG_CACHE_$(1) := $(shell $(2)))$(value DPKG_CACHE_$(1)))

DEB_SOURCE = $(call dpkg_late_eval,DEB_SOURCE,dpkg-parsechangelog -SSource)
DEB_VERSION = $(call dpkg_late_eval,DEB_VERSION,dpkg-parsechangelog -SVersion)
DEB_VERSION_EPOCH_UPSTREAM = $(call dpkg_late_eval,DEB_VERSION_EPOCH_UPSTREAM,echo '$(DEB_VERSION)' | sed -e 's/-[^-]*$$//')
DEB_VERSION_UPSTREAM_REVISION = $(call dpkg_late_eval,DEB_VERSION_UPSTREAM_REVISION,echo '$(DEB_VERSION)' | sed -e 's/^[0-9]*://')
DEB_VERSION_UPSTREAM = $(call dpkg_late_eval,DEB_VERSION_UPSTREAM,echo '$(DEB_VERSION_EPOCH_UPSTREAM)' | sed -e 's/^[0-9]*://')
DEB_DISTRIBUTION = $(call dpkg_late_eval,DEB_DISTRIBUTION,dpkg-parsechangelog -SDistribution)

SOURCE_DATE_EPOCH ?= $(call dpkg_late_eval,SOURCE_DATE_EPOCH,dpkg-parsechangelog -STimestamp)

export SOURCE_DATE_EPOCH
