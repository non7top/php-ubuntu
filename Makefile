.PHONY: help test test-lint test-build test-publish act-version

# You can override these, e.g. `make ACT=act ACT_FLAGS="--pull=false" test`
ACT ?= act
PLATFORM ?= ubuntu-latest=catthehacker/ubuntu:act-22.04
ACT_FLAGS ?= -P $(PLATFORM) --container-architecture linux/amd64
SECRETS_FILE ?= .secrets

help:
	@echo "Targets:"
	@echo "  make test           - run lint + build workflows via act"
	@echo "  make test-lint      - run only lint workflow"
	@echo "  make test-build     - run only build job (matrix)"
	@echo "  make test-publish   - run publish job (requires $(SECRETS_FILE))"
	@echo "  make act-version    - print act version"

act-version:
	$(ACT) --version

# Run both workflows for a quick check
test: test-lint test-build

# Lint workflow (ubuntu-latest)
test-lint:
	$(ACT) -W .github/workflows/lint.yml $(ACT_FLAGS)

# Build workflow: run only the build job to avoid needing publish secrets
# This executes the matrix and uses the job's container images (ubuntu:focal/jammy)
test-build:
	$(ACT) -W .github/workflows/build.yml -j build $(ACT_FLAGS)

# Publish job locally. Requires secrets in $(SECRETS_FILE)
# The secrets file should define APT_GPG_PRIVATE_KEY, APT_GPG_PASSPHRASE, APT_GPG_KEY_ID
# Format is KEY=VALUE per line
# Example file is .secrets.example

test-publish:
	@if [ ! -f $(SECRETS_FILE) ]; then \
		echo "Missing $(SECRETS_FILE). Copy .secrets.example and fill in values."; \
		exit 1; \
	fi
	$(ACT) -W .github/workflows/build.yml -j publish $(ACT_FLAGS) --secret-file $(SECRETS_FILE)
