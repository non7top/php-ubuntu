#!/usr/bin/env bash
set -euo pipefail

# Build PHP from Ondřej's PPA source within a clean container environment.
# Args:
#   1: DIST codename (focal|jammy)
#   2: PHP version (e.g. 8.3, 8.5)
#   3: Output dir for .deb files

DIST=${1:-}
PHP_VER=${2:-}
OUT_DIR=${3:-}

if [[ -z "$DIST" || -z "$PHP_VER" || -z "$OUT_DIR" ]]; then
  echo "Usage: $0 <focal|jammy> <8.3|8.5> <out_dir>" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Base toolchain
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get update
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends git devscripts dpkg-dev build-essential fakeroot python3 dh-php quilt pkg-config flex bison

# Add ondrej/php PPA (both deb and deb-src)
"$(dirname "$0")/setup-ondrej-ppa.sh" "$DIST"

# Ensure universe/multiverse/backports present for build-deps resolution
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu ${DIST} universe"
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu ${DIST} multiverse"
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu ${DIST}-updates universe"
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu ${DIST}-backports main restricted universe multiverse" || true

# Ensure deb-src entries exist (required for apt-get source and build-deps)
# Try to uncomment if present, otherwise add explicit deb-src repositories.
sed -i 's/^#\s*deb-src /deb-src /' /etc/apt/sources.list || true
add-apt-repository -y "deb-src http://archive.ubuntu.com/ubuntu ${DIST} main restricted universe multiverse" || true
add-apt-repository -y "deb-src http://archive.ubuntu.com/ubuntu ${DIST}-updates main restricted universe multiverse" || true
add-apt-repository -y "deb-src http://archive.ubuntu.com/ubuntu ${DIST}-backports main restricted universe multiverse" || true

DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get update

# Try to fetch version-specific source package, fallback to generic 'php'
PKG_NAME="php${PHP_VER}"
if ! DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y source "$PKG_NAME"; then
  echo "Falling back to 'php' source package" >&2
  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y source php
  PKG_NAME="php"
fi

# Enter source tree
SRC_DIR=$(find . -maxdepth 1 -type d -name "${PKG_NAME}*" | head -n1)
if [[ -z "$SRC_DIR" ]]; then
  echo "Source directory not found for ${PKG_NAME}" >&2
  ls -la
  exit 2
fi
cd "$SRC_DIR"

# Install build-deps from debian/control using mk-build-deps
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends equivs
mk-build-deps -i -t "DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y --no-install-recommends" debian/control

# Build binary packages (no signing of .changes)
debuild -b -uc -us

# Collect artifacts
cd ..
find . -maxdepth 1 -type f -name "*.deb" -exec mv -t "$OUT_DIR" {} +
