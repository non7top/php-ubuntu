# GitHub Pages-hosted PPA for PHP

This repository builds PHP 8.3 and 8.5 binary packages for Ubuntu 20.04 (focal) and 22.04 (jammy) using GitHub Actions, assembles an APT repository via `reprepro`, and publishes it to the `pages` branch for GitHub Pages hosting.

Inspired by: https://assafmo.github.io/2019/05/02/ppa-repo-hosted-on-github.html
Source packages pulled from Ondřej Surý's PPA: https://launchpad.net/~ondrej/+archive/ubuntu/php

## What it does
- Matrix builds in containers: `ubuntu:20.04` and `ubuntu:22.04`.
- Fetches `deb` and `deb-src` from `ppa:ondrej/php`.
- Builds PHP `8.3` and `8.5` from source using Debian packaging.
- Publishes `.deb` files into a static APT repo (focal/jammy) on branch `pages`.

## Repository layout
- `.github/workflows/build.yml` — CI pipeline (build + publish)
- `scripts/build-php.sh` — builds PHP from PPA sources inside container
- `scripts/setup-ondrej-ppa.sh` — adds `deb` and `deb-src` entries for ondrej/php
- `repo/conf/distributions` — `reprepro` distributions config for focal/jammy

## Prerequisites
- Enable GitHub Pages for this repo using branch `pages` (source: `pages`, folder: root).
- Add GitHub secrets for signing the repo (recommended):
  - `APT_GPG_PRIVATE_KEY` — ASCII-armored private key.
  - `APT_GPG_PASSPHRASE` — passphrase (if any).
  - `APT_GPG_KEY_ID` — key ID or fingerprint used by `reprepro`.

If you prefer unsigned metadata (not recommended), you can omit the signing secrets and remove `SignWith` from `repo/conf/distributions`; clients will warn.

## Using the repo
Once published, clients can add a line like:

```
# Replace <USER> and <REPO>
deb [trusted=yes] https://<USER>.github.io/<REPO>/ focal main
```

Or with signature trust:
```
wget -qO - https://<USER>.github.io/<REPO>/KEY.gpg | sudo tee /usr/share/keyrings/<REPO>-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/<REPO>-archive-keyring.gpg] https://<USER>.github.io/<REPO>/ focal main" | sudo tee /etc/apt/sources.list.d/<REPO>.list
sudo apt update
```

## Local development
This project is CI-first. If you need to test locally, use Docker containers for focal/jammy and run `scripts/build-php.sh` appropriately.
