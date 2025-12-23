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


# Remove duplicate deb-src lines and ensure only one of each
sed -i 's/^#\s*deb-src /deb-src /' /etc/apt/sources.list || true
for repo in \
  "deb-src http://archive.ubuntu.com/ubuntu ${DIST} main restricted universe multiverse" \
  "deb-src http://archive.ubuntu.com/ubuntu ${DIST}-updates main restricted universe multiverse" \
  "deb-src http://archive.ubuntu.com/ubuntu ${DIST}-backports main restricted universe multiverse"
do
  grep -vFx "$repo" /etc/apt/sources.list > /etc/apt/sources.list.tmp && mv /etc/apt/sources.list.tmp /etc/apt/sources.list
  echo "$repo" >> /etc/apt/sources.list
done

apt-get update

# Create a non-root user for apt-get source to avoid _apt warning
useradd -m builder
chown -R builder:builder .

# Try to fetch version-specific source package, fallback to generic 'php', as non-root
PKG_NAME="php${PHP_VER}"
su builder -c "apt-get -y source $PKG_NAME" || su builder -c "apt-get -y source php"

# Move source tree to output dir
SRC_DIR=$(find . -maxdepth 1 -type d -name "php*")
if [[ -z "$SRC_DIR" ]]; then
  echo "Source directory not found for $PKG_NAME or php" >&2
  ls -la
  exit 2
fi
mv "$SRC_DIR" "$OUT_DIR/"
