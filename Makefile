VERSION := $(shell bash -c '. src/lib/bashLib 2>/dev/null; echo $$BASHLIB_VERSION')
INSTALL_PATH := $(shell python -c 'import sys; print sys.prefix if hasattr(sys, "real_prefix") else "/usr/local"')
LIB_COMPONENTS := $(wildcard src/lib/bashLib-latest/*)

.PHONY: tests clean help build

all: build

help:
	@echo "Usage: make build|tests|all|clean|version|install"

build: build/lib/bashLib build/bin/bashlibtool

tests: build
	@PATH="$(shell readlink -f build/bin):$(PATH)" unittests/testsuite

examples/%: build
	@cd $@ && PATH="$(shell readlink -f build/bin):$(PATH)" ./run

install: tests
	@rsync -az build/ $(INSTALL_PATH)/

version: all
	@build/bin/bashlibtool --version

build/lib/bashLib: build/lib/bashLib-$(VERSION) build/lib src/lib/bashLib
	@install -m 755 src/lib/bashLib $@

build/lib/bashLib-$(VERSION): build/lib $(LIB_COMPONENTS)
	@rsync -az src/lib/bashLib-latest/ $@/

build/share/bashLib: build/share
	@mkdir $@

build/share/bashLib/examples: build/share/bashLib
	@rsync -az examples/ $@/

build/bin/bashlibtool: build/lib/bashLib build/bin | src/tools
	@install -m 755 src/tools/bashlibtool $@

build/%:
	@install -d $@

clean:
	-@rm -rf build checkouts
