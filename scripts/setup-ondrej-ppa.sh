#!/usr/bin/env bash
set -euo pipefail

DIST_CODENAME=${1:-}
if [[ -z "$DIST_CODENAME" ]]; then
  echo "Usage: $0 <focal|jammy>" >&2
  exit 1
fi


# Always run apt non-interactively
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC

export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get update
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends software-properties-common ca-certificates gnupg wget

# Add Ondřej's PPA (deb) and (deb-src) explicitly for the target codename
cat >/etc/apt/sources.list.d/ondrej-php.list <<EOF
deb https://ppa.launchpadcontent.net/ondrej/php/ubuntu ${DIST_CODENAME} main
deb-src https://ppa.launchpadcontent.net/ondrej/php/ubuntu ${DIST_CODENAME} main
EOF

# Import signing key from keyserver
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B8DC7E53946656EFBCE4C1DD71DAEAAB4AD4CAB6 || true

DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get update
