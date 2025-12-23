# Contributing

## Always run tests before pushing

Run the local test suite to catch issues early.

```
make test          # runs lint + build via act
make test-lint     # runs only the lint workflow
make test-build    # runs only the build job matrix
make test-publish  # runs publish job (requires .secrets)
```

## Set up pre-commit

Install and enable pre-commit hooks to enforce style and basic checks.

```
python3 -m pip install --user pre-commit
pre-commit install
# On first run against entire repo:
pre-commit run --all-files
```

Hooks included:
- trailing whitespace, end-of-file, YAML checks
- shellcheck and shfmt for scripts in `scripts/`
- yamllint for `.github/workflows/*.yml`
- codespell for typos

Docker is required for some hooks (shellcheck/shfmt/yamllint) and for `act`.

## Secrets for local publish

To test the publish job locally:
- Copy `.secrets.example` to `.secrets`
- Fill in `APT_GPG_PRIVATE_KEY`, `APT_GPG_PASSPHRASE`, `APT_GPG_KEY_ID`
- Run `make test-publish`
