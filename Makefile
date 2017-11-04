VERSION := $(shell bash -c '. src/lib/bashLib 2>/dev/null; echo $$BASHLIB_VERSION')
INSTALL_PATH := $(shell python -c 'import sys; print sys.prefix if hasattr(sys, "real_prefix") else "/usr/local"')

.PHONY: tests clean help

all: build

help:
	@echo "Usage: make build|tests|all|clean|version|install"

build: build/lib/bashLib build/bin/bashlibtool

install: tests
	@rsync -az build/ $(INSTALL_PATH)/

version: all
	@build/bin/bashlibtool --version

build/lib/bashLib: build/lib/bashLib-$(VERSION) build/lib
	@install -m 755 src/lib/bashLib $@

build/lib/bashLib-$(VERSION): build/lib
	@rsync -az src/lib/bashLib-latest/ $@/

build/share/bashLib: build/share
	@mkdir $@

build/share/bashLib/examples: build/share/bashLib
	@rsync -az examples/ $@/

build/bin/bashlibtool: build/lib/bashLib build/bin
	@install -m 755 src/tools/bashlibtool $@

build/%:
	@install -d $@

tests: build
	@PATH="$(shell readlink -f build/bin):$(PATH)" unittests/testsuite

clean:
	-@rm -rf build checkouts
