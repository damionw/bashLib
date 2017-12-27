PACKAGE_NAME := bashLib
PACKAGE_VERSION := $(shell bash -c '. src/lib/$(PACKAGE_NAME) 2>/dev/null; echo $$BASHLIB_VERSION')
INSTALL_PATH := $(shell python -c 'import sys; print sys.prefix if hasattr(sys, "real_prefix") else "/usr/local"')
LIB_COMPONENTS := $(wildcard src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/*)

.PHONY: tests clean help build

all: build

help:
	@echo "Usage: make build|tests|all|clean|version|install"

build: build/lib/$(PACKAGE_NAME) build/bin/bashlibtool

tests: build
	@PATH="$(shell readlink -f build/bin):$(PATH)" unittests/testsuite

examples/%: build
	@cd $@ && PATH="$(shell readlink -f build/bin):$(PATH)" ./run

install: tests
	@rsync -az build/ $(INSTALL_PATH)/

version: all
	@build/bin/bashlibtool --version

build/lib/$(PACKAGE_NAME): build/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION) build/lib src/lib/$(PACKAGE_NAME)
	@install -m 755 src/lib/$(PACKAGE_NAME) $@

build/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION): build/lib $(LIB_COMPONENTS)
	@rsync -az src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/ $@/

build/share/$(PACKAGE_NAME): build/share
	@mkdir $@

build/share/$(PACKAGE_NAME)/examples: build/share/$(PACKAGE_NAME)
	@rsync -az examples/ $@/

build/bin/bashlibtool: build/lib/$(PACKAGE_NAME) build/bin | src/tools
	@install -m 755 src/tools/bashlibtool $@

build/%:
	@install -d $@

clean:
	-@rm -rf build checkouts
