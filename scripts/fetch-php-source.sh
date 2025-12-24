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
  REPO_PATTERN=$(echo "$repo" | sed 's/ /\\s\+/g')
  echo "Checking for deb-src line: $repo" >&2
  if grep -E -q "^\s*deb-src\s+$REPO_PATTERN" /etc/apt/sources.list; then
    echo "SKIP: Already present (pattern: $REPO_PATTERN)" >&2
  else
    echo "ADD: $repo" >&2
    echo "$repo" >> /etc/apt/sources.list
  fi
done

# Debug: print the whole sources.list after all changes
echo "\n===== /etc/apt/sources.list after changes =====" >&2
cat /etc/apt/sources.list >&2

apt-get update



# Create a non-root user for apt-get source to avoid _apt warning
useradd -m builder || true

# Use a temp directory in /tmp for builder's activity
BUILDER_TMPDIR="/tmp/php-src-fetch-$$"
mkdir -p "$BUILDER_TMPDIR"
chown builder:builder "$BUILDER_TMPDIR"
cd "$BUILDER_TMPDIR"



PKG_NAME="php${PHP_VER}"
echo "Fetching source for $PKG_NAME (or fallback to php) as builder user..."
if ! su builder -c "apt-get -y source $PKG_NAME"; then
  echo "Failed to fetch source for $PKG_NAME, trying generic 'php'..."
  if ! su builder -c "apt-get -y source php"; then
    echo "ERROR: Failed to fetch source for $PKG_NAME and for generic 'php'." >&2
    exit 2
  fi
fi

# Debug: print contents of temp directory after source fetch
echo "Contents of $BUILDER_TMPDIR after apt-get source:" >&2
ls -la "$BUILDER_TMPDIR" >&2


# Move source tree to output dir
# Find the actual PHP source directory (not the temp dir itself)
SRC_DIR=$(find "$BUILDER_TMPDIR" -mindepth 1 -maxdepth 1 -type d -name "php*")
SRC_DIR=$(echo "$SRC_DIR" | head -n 1 | tr -d '\n' | xargs)
if [[ -z "$SRC_DIR" ]]; then
  echo "ERROR: Source directory not found for $PKG_NAME or php after apt-get source." >&2
  echo "Contents of $BUILDER_TMPDIR:" >&2
  ls -la "$BUILDER_TMPDIR" >&2
  exit 3
else
  echo "Copying source directory: '$SRC_DIR' to '$OUT_DIR/'" >&2
  cp -a "$SRC_DIR" "$OUT_DIR/"
fi
# Clean up temp dir
rm -rf "$BUILDER_TMPDIR"
