# Local Testing with act

This repository includes a Makefile to run the GitHub Actions workflows locally using [nektos/act](https://github.com/nektos/act).

## Install act

One way to install:

```
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

## Quick start

```
make test          # run lint and build jobs
make test-lint     # run only the lint workflow
make test-build    # run only the build matrix
make test-publish  # run publish job (requires .secrets)
```

## Notes
- Platform mapping for `ubuntu-latest` is set in [.actrc](../.actrc). Override with `make ACT_FLAGS="-P ubuntu-latest=catthehacker/ubuntu:act-24.04"` if desired.
- For `make test-publish`, copy [.secrets.example](../.secrets.example) to `.secrets` and populate `APT_GPG_*` secrets.
- `act` uses Docker. Ensure Docker is installed and your user can run it.
- The `test-build` target runs only the `build` job to avoid requiring GPG secrets; `publish` is separate.
