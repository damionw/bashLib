PACKAGE_NAME := bashLib
PACKAGE_VERSION := $(shell bash -c '. src/lib/$(PACKAGE_NAME) 2>/dev/null; bashlib::version')
INSTALL_PATH := $(shell python -c 'import sys; print sys.prefix if hasattr(sys, "real_prefix") else exit(255)' 2>/dev/null || echo "/usr/local")
LIB_COMPONENTS := $(wildcard src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/*)
BIN_COMPONENTS := $(foreach name, $(wildcard src/bin/*), build/bin/$(notdir $(name)))
DIR_COMPONENTS := $(foreach name, bin share lib, build/$(name)) build/share/$(PACKAGE_NAME)

.PHONY: tests clean help build

all: build

help:
	@echo "Usage: make [build|tests|all|clean|version|install]"

build: build/lib/$(PACKAGE_NAME) $(BIN_COMPONENTS) build/share/$(PACKAGE_NAME)/examples

tests: build
	@PATH="$(shell readlink -f build/bin):$(PATH)" unittests/testsuite

examples/%: build
	@cd $@ && PATH="$(shell readlink -f build/bin):$(PATH)" ./run

install: tests
	@rsync -az build/ $(INSTALL_PATH)/

version: all
	@build/bin/bashlib --version

build/lib/$(PACKAGE_NAME): build/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION) build/lib src/lib/$(PACKAGE_NAME)
	@install -m 755 src/lib/$(PACKAGE_NAME) $@

build/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION): build/lib $(LIB_COMPONENTS)
	@rsync -az src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/ $@/

build/share/$(PACKAGE_NAME)/examples: build/share/$(PACKAGE_NAME)
	@rsync -az examples/ $@/

build/bin/%: build/lib/$(PACKAGE_NAME) build/bin | src/bin
	@install -m 755 src/bin/$(notdir $@) $@

$(DIR_COMPONENTS):
	@install -d $@

clean:
	-@rm -rf build checkouts testdata