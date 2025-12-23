#!/usr/bin/env bash
set -euo pipefail

# Fetch PHP source from Ondřej's PPA on the newest supported Ubuntu (jammy)
# Args:
#   1: PHP version (e.g. 8.3)
#   2: Output dir for source tree

PHP_VER=${1:-}
OUT_DIR=${2:-}

if [[ -z "$PHP_VER" || -z "$OUT_DIR" ]]; then
  echo "Usage: $0 <8.3> <out_dir>" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Use Ubuntu jammy for fetching source
DIST=jammy

# Base toolchain
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC
apt-get update
apt-get install -y --no-install-recommends tzdata git devscripts dpkg-dev build-essential fakeroot python3 dh-php quilt pkg-config flex bison software-properties-common ca-certificates gnupg wget

# Add ondrej/php PPA (deb and deb-src)
SCRIPT_DIR="$(dirname "$0")"
"$SCRIPT_DIR/setup-ondrej-ppa.sh" "$DIST"

# Ensure deb-src entries exist (avoid duplicates)
sed -i 's/^#\s*deb-src /deb-src /' /etc/apt/sources.list || true
add_deb_src() {
    local entry="$1"
    grep -Fxq "$entry" /etc/apt/sources.list || echo "$entry" >> /etc/apt/sources.list
}
add_deb_src "deb-src http://archive.ubuntu.com/ubuntu ${DIST} main restricted universe multiverse"
add_deb_src "deb-src http://archive.ubuntu.com/ubuntu ${DIST}-updates main restricted universe multiverse"
add_deb_src "deb-src http://archive.ubuntu.com/ubuntu ${DIST}-backports main restricted universe multiverse"

apt-get update

# Try to fetch version-specific source package, fallback to generic 'php'
PKG_NAME="php${PHP_VER}"
if ! apt-get -y source "$PKG_NAME"; then
  apt-get -y source php
fi

# Move source tree to output dir
SRC_DIR=$(find . -maxdepth 1 -type d -name "php*")
if [[ -z "$SRC_DIR" ]]; then
  echo "Source directory not found for $PKG_NAME or php" >&2
  ls -la
  exit 2
fi
mv "$SRC_DIR" "$OUT_DIR/"
