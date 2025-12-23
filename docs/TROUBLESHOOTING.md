# Troubleshooting

## "You must put some 'deb-src' URIs in your sources.list"
This happens when source repositories are disabled in the Ubuntu image. The CI build fixes this automatically by:
- Enabling Ubuntu `deb-src` entries in scripts/build-php.sh.
- Adding `deb-src` for Ondřej’s PPA in scripts/setup-ondrej-ppa.sh.

No action is needed in CI. For local Docker runs, ensure you execute these scripts inside the container before running `apt-get source` or building.

## Re-running the build
- Go to GitHub → Actions → "Build PHP PPA" → Run workflow.
- The pipeline rebuilds packages for focal and jammy and republishes the APT repo on the `pages` branch.

## Missing signing key
If publishing without `APT_GPG_*` secrets, the repo will be unsigned and clients may warn. Provide:
- `APT_GPG_PRIVATE_KEY` (ASCII armored)
- `APT_GPG_PASSPHRASE` (if any)
- `APT_GPG_KEY_ID`
