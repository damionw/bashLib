PACKAGE_NAME := bashLib
PACKAGE_VERSION := $(shell bash -c '. src/lib/$(PACKAGE_NAME) 2>/dev/null; bashlib::version')
INSTALL_PATH := $(shell python -c 'import sys; print sys.prefix if hasattr(sys, "real_prefix") else exit(255)' 2>/dev/null || echo "/usr/local")
LIB_COMPONENTS := $(wildcard src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/*)
BIN_COMPONENTS := $(foreach name, $(wildcard src/bin/*), build/bin/$(notdir $(name)))
DIR_COMPONENTS := $(foreach name, bin share lib, build/$(name)) build/share/$(PACKAGE_NAME)

.PHONY: tests clean help build

all: updates build

help:
	@echo "Usage: make [build|tests|all|clean|version|install]"

updates: src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/option_parsing

build: build/lib/$(PACKAGE_NAME) $(BIN_COMPONENTS) build/share/$(PACKAGE_NAME)/examples

tests: build
	@PATH="$(shell readlink -f build/bin):$(PATH)" unittests/testsuite

examples/%: build
	@cd $@ && PATH="$(shell readlink -f build/bin):$(PATH)" ./run

install-private: tests $(HOME)/bin
	@echo "Privately installing into directory '$(HOME)'"
	@echo $$PATH | tr '\\:' '\n' | grep -q '^'"$$HOME/bin"'$$'
	@rsync -az build/ $(HOME)/

install: tests
	@echo "Installing into directory '$(INSTALL_PATH)'"
	@rsync -az build/ $(INSTALL_PATH)/

version: all
	@build/bin/bashlib --version

src/lib/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/option_parsing: checkouts/optionslib/build/parse

checkouts/optionslib/build/parse: checkouts/optionslib
	@cp $</build/lib/optionslib-$(shell $</build/bin/optionslib --version)/parse $@

checkouts/optionslib: checkouts
	@git clone https://github.com/damionw/optionslib.git $@
	@$(MAKE) -C $@ all

checkouts:
	@install -d $@

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
