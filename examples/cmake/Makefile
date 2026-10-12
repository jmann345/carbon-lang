# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Explicit GNU make rules for the same three programs the CMake project in
# this directory builds (see /docs/guides/build_systems.md, "Make"). Every
# object's prerequisites are the whole Carbon package, because the driver
# writes one object per invocation and needs every file of the package on the
# command line. Usage:
#
#   make CARBON_TOOLCHAIN=<toolchain directory> [O=<build directory>] all
#   make CARBON_TOOLCHAIN=<toolchain directory> run

# Toolchain directory: the unpacked tarball, the parent of bin/carbon. An
# explicit CARBON_TOOLCHAIN wins over an exported CARBON, so every tool comes
# from one toolchain; `:=` still yields to a command-line `make CARBON=...`.
ifeq ($(origin CARBON_TOOLCHAIN),undefined)
  ifeq ($(origin CARBON),undefined)
    $(error set CARBON_TOOLCHAIN=<toolchain directory> or CARBON=<path to bin/carbon>)
  endif
  CARBON_TOOLCHAIN := $(abspath $(dir $(CARBON))..)
else
  CARBON := $(CARBON_TOOLCHAIN)/bin/carbon
endif
# CXX, CC and AR are GNU make builtins (origin "default"), so `?=` would
# keep g++; `:=` still yields to a command-line `make CXX=...`.
CXX := $(CARBON_TOOLCHAIN)/lib/carbon/llvm/bin/clang++
CORE := $(CARBON_TOOLCHAIN)/lib/carbon/core
O ?= build-make

all: $(O)/hello $(O)/widget_main $(O)/mixed

$(O):
	mkdir -p $@
$(O)/io.impl.o: $(CORE)/io.carbon $(CORE)/io.impl.carbon | $(O)
	$(CARBON) compile --no-include-carbon-core --output-last-input-only \
	  --output=$@ $(CORE)/io.carbon $(CORE)/io.impl.carbon
$(O)/hello.o: hello/hello.carbon | $(O)
	$(CARBON) compile --output-last-input-only --output=$@ $<
$(O)/hello: $(O)/hello.o $(O)/io.impl.o
	$(CARBON) link --output=$@ $^
$(O)/widget.impl.o: widget/widget.carbon widget/widget.impl.carbon | $(O)
	$(CARBON) compile --output-last-input-only --output=$@ \
	  widget/widget.carbon widget/widget.impl.carbon
$(O)/widget_main.o: widget/widget.carbon widget/widget.impl.carbon widget/main.carbon | $(O)
	$(CARBON) compile --output-last-input-only --output=$@ \
	  widget/widget.carbon widget/widget.impl.carbon widget/main.carbon
$(O)/widget_main: $(O)/widget_main.o $(O)/widget.impl.o $(O)/io.impl.o
	$(CARBON) link --output=$@ $^
$(O)/twice.o: mixed/twice.cpp mixed/twice.h | $(O)
	$(CXX) -std=c++17 -c -o $@ mixed/twice.cpp
$(O)/mixed.o: mixed/main.carbon mixed/twice.h | $(O)
	$(CARBON) compile --clang-arg=-Imixed --output-last-input-only --output=$@ mixed/main.carbon
$(O)/mixed: $(O)/mixed.o $(O)/twice.o
	$(CARBON) link --output=$@ $^

# Stage targets: `objects` compiles everything, `link` links everything, so
# a driver (examples/cmake/test.sh) can tell a compile failure from a link
# failure.
objects: $(O)/io.impl.o $(O)/hello.o $(O)/widget.impl.o $(O)/widget_main.o \
  $(O)/twice.o $(O)/mixed.o
link: all
run: all
	$(O)/hello && $(O)/widget_main && $(O)/mixed
clean:
	rm -rf $(O)

.PHONY: all objects link run clean
