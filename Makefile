# Edemint top-level Makefile — convenience wrapper around build.sh.
# Real builds happen in CI on a privileged runner (live-build / mmdebstrap
# need root + loop devices). Local builds work on a Linux box with sudo.

SHELL := /bin/sh
REPO := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

.PHONY: help iso pi metapackages clean lint sign-test test all

help:
	@echo "Edemint build targets:"
	@echo "  make iso           amd64 live ISO (sudo)"
	@echo "  make pi            arm64 Raspberry Pi image (sudo)"
	@echo "  make metapackages  build the equivs .debs only"
	@echo "  make lint          Tier A static checks (no root needed)"
	@echo "  make sign-test     apt repo sign + tamper-reject self-test"
	@echo "  make clean         remove build artifacts"

all: iso pi

iso:
	$(REPO)build.sh amd64

pi:
	$(REPO)build.sh pi

metapackages:
	$(REPO)packaging/build-metapackages.sh

clean:
	$(REPO)build.sh clean

lint:
	$(REPO)scripts/tier-a-lint.sh

sign-test: metapackages
	$(REPO)scripts/test-repo-signing.sh

test: lint sign-test metapackages
