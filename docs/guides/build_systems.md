# Build systems: CMake and Make

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Toolchain layout](#toolchain-layout)
-   [CMake](#cmake)
    -   [Enabling the language](#enabling-the-language)
    -   [Finding the compiler](#finding-the-compiler)
    -   [Flags and configurations](#flags-and-configurations)
    -   [A single-file executable](#a-single-file-executable)
    -   [Core libraries](#core-libraries)
    -   [A multi-file package](#a-multi-file-package)
    -   [Mixed Carbon and C++](#mixed-carbon-and-c)
    -   [Shared libraries](#shared-libraries)
-   [Make](#make)
    -   [The rules](#the-rules)
    -   [The `carbon build` one-liner](#the-carbon-build-one-liner)
-   [Limits in 0.1](#limits-in-01)

<!-- tocstop -->

## Overview

This guide shows how to build Carbon programs with an installed toolchain (the
nightly tarball) from CMake and from GNU make, and how to mix Carbon and C++ in
one program with the toolchain's own drop-in `clang++`. The CMake support is
the set of language modules in [/cmake](/cmake/README.md); the worked example
for both build systems is [/examples/cmake](/examples/cmake/README.md), whose
`test.sh` builds the same three programs under the Unix Makefiles generator,
the Ninja generator and a plain Makefile and compares their output. Every
command below was run against `carbon_toolchain-0.0.0-0.nightly.2026.10.12`
with CMake 3.28.3, GNU make 4.3 and ninja 1.11.1.

## Toolchain layout

Unpacking `carbon_toolchain-<version>.tar.gz` gives a _toolchain directory_
with this shape:

```text
carbon_toolchain-<version>/
  bin/carbon                      # the driver (a symlink into lib/carbon/)
  lib/carbon/carbon-busybox       # the one binary behind every tool
  lib/carbon/llvm/bin/clang++     # the drop-in Clang (also clang, ld.lld, ...)
  lib/carbon/core/                # the Core package's sources (io.carbon, ...)
  lib/carbon/core/core_library_manifest.txt
```

`carbon config --json` prints the layout the driver itself uses; the two keys
the CMake modules read are `INSTALL_ROOT`, which is the _install root_
`<toolchain directory>/lib/carbon/`, and `LLVM_BINDIR`,
`<install root>/llvm/bin`. Keep the two terms apart: the example project and
the Makefile take the toolchain directory (`CARBON_TOOLCHAIN`), while the CMake
variable `CMAKE_Carbon_INSTALL_ROOT` holds the install root, so the Core
sources are at `${CMAKE_Carbon_INSTALL_ROOT}/core/`.

Two facts about the driver shape everything that follows:

-   `carbon compile` writes **one object per invocation**, for its last input,
    and every file of a package must be on that one command line (a unit
    compiled alone fails with `imported API 'Main//widget' not found`).
-   `carbon link` adds the prelude objects and the runtimes itself, but **not
    the rest of Core**: a program calling `Core.PrintStr` or `Core.EOF` needs an
    object compiled from `core/io.impl.carbon` on its link line.

## CMake

### Enabling the language

The modules under `/cmake` make `Carbon` a CMake language. Put that directory
on `CMAKE_MODULE_PATH` before `project()` and name the language; include
`CarbonTargets` for the package helpers:

```cmake
cmake_minimum_required(VERSION 3.28)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake")
project(carbon_cmake_example LANGUAGES Carbon CXX)
include(CarbonTargets)
```

`.carbon` sources (including `.impl.carbon` files) are then first-class:
`add_executable`, `add_library(... STATIC|OBJECT ...)`,
`target_link_libraries`, `target_include_directories`,
`target_compile_definitions`, `$<TARGET_OBJECTS:...>` and per-configuration
flags all work without generator-specific code. The modules are not installed
into the toolchain tree yet, so there is no `find_package(Carbon)`; see
"Limits".

### Finding the compiler

CMake finds `carbon` in this order:

1.  the `CMAKE_Carbon_COMPILER` cache entry
    (`-DCMAKE_Carbon_COMPILER=<toolchain directory>/bin/carbon`);
2.  the `CARBON` environment variable;
3.  `carbon` (or `carbon-busybox`) on `PATH`.

It identifies the compiler from `carbon version` (the configure output says
`The Carbon compiler identification is Carbon 0.0.0-0.nightly...`), proves it
works with a one-line `try_compile`, and records `CMAKE_Carbon_INSTALL_ROOT`
and `CMAKE_Carbon_LLVM_BINDIR` from `carbon config --json`.

The example project adds a convenience on top: a `CARBON_TOOLCHAIN` cache entry
or environment variable naming the toolchain directory, read **before**
`project()`, seeds both the Carbon compiler and `CMAKE_CXX_COMPILER` (the
toolchain's `lib/carbon/llvm/bin/clang++`) unless the user set them. With
neither, it resolves `carbon` from `PATH` through its symlink: the real path is
`lib/carbon/carbon-busybox`, three directories below the toolchain directory.

```cmake
if(NOT CARBON_TOOLCHAIN AND NOT "$ENV{CARBON_TOOLCHAIN}" STREQUAL "")
  set(CARBON_TOOLCHAIN "$ENV{CARBON_TOOLCHAIN}" CACHE PATH
    "Carbon toolchain directory (the parent of bin/carbon)")
endif()
if(NOT CARBON_TOOLCHAIN)
  find_program(_carbon_on_path carbon)
  if(_carbon_on_path)
    get_filename_component(_carbon_busybox "${_carbon_on_path}" REALPATH)
    get_filename_component(_carbon_dir "${_carbon_busybox}" PATH)
    get_filename_component(_carbon_dir "${_carbon_dir}" PATH)
    get_filename_component(CARBON_TOOLCHAIN "${_carbon_dir}" PATH)
  endif()
endif()
if(CARBON_TOOLCHAIN)
  if(NOT CMAKE_Carbon_COMPILER)
    set(CMAKE_Carbon_COMPILER "${CARBON_TOOLCHAIN}/bin/carbon")
  endif()
  if(NOT CMAKE_CXX_COMPILER)
    set(CMAKE_CXX_COMPILER "${CARBON_TOOLCHAIN}/lib/carbon/llvm/bin/clang++")
  endif()
endif()
```

So the whole example configures and builds with:

```shell
cmake -S examples/cmake -B build -DCARBON_TOOLCHAIN=/path/to/carbon_toolchain-<version>
cmake --build build
```

### Flags and configurations

`CMAKE_Carbon_FLAGS` and its per-configuration variants are ordinary cache
entries. The defaults map onto `carbon compile`'s optimization levels:

| Configuration    | Default flags                     |
| ---------------- | --------------------------------- |
| `Debug`          | `--optimize=none`                 |
| `Release`        | `--optimize=speed --no-debug-info` |
| `RelWithDebInfo` | `--optimize=speed`                |
| `MinSizeRel`     | `--optimize=size --no-debug-info` |

`CMAKE_Carbon_FLAGS` is seeded from the `CARBONFLAGS` environment variable at
the first configure, and the linker-flag variables from `LDFLAGS`. Flags reach
compile lines only: `carbon link` takes no `compile` options, so the link rule
deliberately omits `<FLAGS>`. Include directories become `--clang-arg=-I...`
and definitions `--clang-arg=-D...`, which is how the Clang embedded in the
toolchain sees them for `import Cpp library`.

### A single-file executable

```cmake
carbon_add_core_library(io)
add_executable(hello hello/hello.carbon)
target_link_libraries(hello PRIVATE Carbon::core_io)
```

`hello/hello.carbon` imports `Core library "io"` and calls `Core.PrintStr`,
which is why it links `Carbon::core_io` (next section). The generated
commands, quoted from the Unix Makefiles generator's `build.make` and
`link.txt`:

```text
<tc>/bin/carbon compile $(Carbon_DEFINES) $(Carbon_INCLUDES) $(Carbon_FLAGS) --output-last-input-only --output=CMakeFiles/hello.dir/hello/hello.carbon.o <src>/hello/hello.carbon
<tc>/bin/carbon link --output=hello CMakeFiles/hello.dir/hello/hello.carbon.o --  libcarbon_core_io.a
```

and from the Ninja generator's `rules.ninja`:

```text
rule Carbon_COMPILER__hello_unscanned_
  command = ${LAUNCHER}${CODE_CHECK}<tc>/bin/carbon compile $DEFINES $INCLUDES $FLAGS --output-last-input-only --output=$out $in
rule Carbon_EXECUTABLE_LINKER__hello_
  command = $PRE_LINK && <tc>/bin/carbon link --output=$TARGET_FILE $in -- $LINK_FLAGS $LINK_PATH $LINK_LIBRARIES && $POST_BUILD
```

`--output-last-input-only` sits in the rule itself. It is silent for a single
input and lets the package helpers put sibling files before the source. The
Ninja rule carries `depfile = $DEP_FILE` and `deps = gcc` like every language,
but nothing writes that file (`ninja -t deps` reports zero dependencies for a
Carbon object): header dependencies are explicit, see "Mixed Carbon and C++".

### Core libraries

`carbon link` links the prelude objects it finds in its runtimes cache and
stops there — `toolchain/driver/link_driver.cpp` carries the TODO "should also
be able to link in the rest of the Core object files". `Core.PrintStr` and
`Core.EOF` have their bodies in `core/io.impl.carbon`, so without that object a
link fails with `ld.lld: error: undefined symbol: _CPrintStr.Core`.

`carbon_add_core_library(io)` builds the Core library `io` from the toolchain's
own sources as the static target `carbon_core_io` with the alias
`Carbon::core_io`. It reads `core/core_library_manifest.txt` under the install
root for the library's files (`io.carbon` and `io.impl.carbon`), compiles them
with `--no-include-carbon-core` — the flag is only right for Core's own
sources; passing it to a user package breaks `import Core library "io"` — and
archives the two objects. Link it from every executable that calls into
`Core.io`; it mirrors the implicit `//core:io` dependency of the Bazel
`carbon_binary` rule, made explicit because a module cannot add link inputs to
targets it does not own.

### A multi-file package

A package with an API file and an implementation file is a library target,
and a consumer declares the dependency:

```cmake
carbon_add_library(widget STATIC
  SOURCES widget/widget.carbon widget/widget.impl.carbon)
carbon_add_executable(widget_main SOURCES widget/main.carbon DEPS widget)
target_link_libraries(widget_main PRIVATE Carbon::core_io)
```

`carbon_add_library(<name> [STATIC|OBJECT] SOURCES <files...> [DEPS <carbon
libraries...>] [NO_CORE])` and `carbon_add_executable(<name> SOURCES
<files...> [DEPS <carbon libraries...>])` wire the package: for every source,
the other files of the package plus the API files of each `DEPS` library (its
sources not ending in `.impl.carbon`, published through the target property
`CARBON_API_FILES`, transitively) are added as per-source `COMPILE_OPTIONS`,
so they precede the source on its command line, and as `OBJECT_DEPENDS`, so
the object rebuilds when any of them changes. `DEPS` also links the archive
(`PUBLIC` for libraries, `PRIVATE` for executables). The generated compile
lines from `build.make`:

```text
<tc>/bin/carbon compile $(Carbon_DEFINES) $(Carbon_INCLUDES) $(Carbon_FLAGS) <src>/widget/widget.impl.carbon --output-last-input-only --output=CMakeFiles/widget.dir/widget/widget.carbon.o <src>/widget/widget.carbon
<tc>/bin/carbon compile $(Carbon_DEFINES) $(Carbon_INCLUDES) $(Carbon_FLAGS) <src>/widget/widget.carbon --output-last-input-only --output=CMakeFiles/widget.dir/widget/widget.impl.carbon.o <src>/widget/widget.impl.carbon
<tc>/bin/carbon compile $(Carbon_DEFINES) $(Carbon_INCLUDES) $(Carbon_FLAGS) <src>/widget/widget.carbon --output-last-input-only --output=CMakeFiles/widget_main.dir/widget/main.carbon.o <src>/widget/main.carbon
```

and the archive and link lines:

```text
/usr/bin/ar qc libwidget.a CMakeFiles/widget.dir/widget/widget.carbon.o CMakeFiles/widget.dir/widget/widget.impl.carbon.o
/usr/bin/ranlib libwidget.a
<tc>/bin/carbon link --output=widget_main CMakeFiles/widget_main.dir/widget/main.carbon.o --  libwidget.a libcarbon_core_io.a
```

Under Ninja the sibling files appear as the object's `FLAGS` and as order-only
inputs of the `build` statement; the rule is the one quoted above. Each unit of
the package re-parses the whole package, and `widget.carbon.o` (the API file's
object) holds no symbols — only the impl object defines `Get`. Carbon objects
are plain ELF objects, so the system `ar` and `llvm-ar` both archive them.

Source-file properties are per directory. A `.carbon` file wired into two
packages from one `CMakeLists.txt` would receive both sibling lists, so the
helper refuses it with a configure error naming both targets; build such a
file once as an `OBJECT` library and consume `$<TARGET_OBJECTS:...>`.

### Mixed Carbon and C++

A Carbon unit imports a C++ header, the C++ half is an ordinary CXX library,
and the whole program is linked by `carbon link`:

```cmake
add_library(twice STATIC mixed/twice.cpp)
target_include_directories(twice PUBLIC mixed)
add_executable(mixed mixed/main.carbon)
set_source_files_properties(mixed/main.carbon PROPERTIES
  OBJECT_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/mixed/twice.h")
target_link_libraries(mixed PRIVATE twice)
```

Three things make this work:

-   **The drop-in clang++ compiles the C++.** The example seeds
    `CMAKE_CXX_COMPILER` with the toolchain's `lib/carbon/llvm/bin/clang++`
    (identified as `Clang 24.0.0`); a user-set compiler wins. Objects built by
    a system `g++` do **not** link this way: CMake then appends `-lstdc++`,
    the Clang driver rewrites it to `-lc++`, and the link fails with
    `undefined symbol: std::__throw_length_error`. The measured workaround for
    g++ objects is to pass the system library by path after the `--`, for
    example `-- /usr/lib/x86_64-linux-gnu/libstdc++.so.6`; the alternative of
    letting g++ drive the link with the prelude objects passed explicitly is
    not part of this release (W-131).
-   **Include directories propagate.** The library's `PUBLIC` include
    directory reaches the Carbon compile line as
    `--clang-arg=-I<src>/mixed`, which is what resolves
    `import Cpp library "twice.h"`.
-   **The linker language is Carbon.** `CMAKE_Carbon_LINKER_PREFERENCE` is 40
    against C++'s 30 and propagates through static libraries, so `carbon link`
    links the Carbon object, the C++ archive and the CXX compiler's implicit
    link entries. Without the preference, CMake would hand the link to
    `clang++`, which does not add the prelude objects.

The header dependency is explicit: `carbon compile` writes no dependency file
(W-129), so `twice.h` is listed in `OBJECT_DEPENDS` of `mixed/main.carbon`,
and editing it rebuilds `main.carbon.o` and relinks under both generators. The
generated lines:

```text
<tc>/bin/carbon compile $(Carbon_DEFINES) $(Carbon_INCLUDES) $(Carbon_FLAGS) --output-last-input-only --output=CMakeFiles/mixed.dir/mixed/main.carbon.o <src>/mixed/main.carbon
<tc>/lib/carbon/llvm/bin/clang++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/twice.dir/mixed/twice.cpp.o -MF CMakeFiles/twice.dir/mixed/twice.cpp.o.d -o CMakeFiles/twice.dir/mixed/twice.cpp.o -c <src>/mixed/twice.cpp
<tc>/bin/carbon link --output=mixed CMakeFiles/mixed.dir/mixed/main.carbon.o --  -L<runtimes cache>/libunwind/lib -L<runtimes cache>/libcxx/lib -L<runtimes cache>/clang_resource_dir/lib/x86_64-unknown-linux-gnu -L<tc>/lib/carbon/llvm/lib ... libtwice.a -lc++ -lm -lunwind -lc -lunwind
```

with `Carbon_INCLUDES = --clang-arg=-I<src>/mixed` in the object's
`flags.make`. One thing to know about that link line: CMake appends the CXX
compiler's implicit link libraries and directories
(`CMAKE_CXX_IMPLICIT_LINK_LIBRARIES` and `_DIRECTORIES`, detected at configure
from `clang++`) after the `--`. They are tolerated by `carbon link`, and they
include a `-L` of the user's `$HOME/.cache/carbon_runtimes/...` directory baked
into the build tree, because the drop-in `clang++` found its runtimes there.
If a future toolchain objects to a duplicated `-lc++` or `-lunwind`, reset
those two variables to empty after `project()`.

### Shared libraries

`carbon link` has no shared-library mode (W-132). `add_library(x SHARED
a.carbon)` and `MODULE` targets configure but fail at build time under every
generator — the module pins their rules to a command that always fails — rather
than appearing to succeed: with the rules left undefined, the Ninja generator
links a Carbon shared library as `: && :` and exits 0 without writing it. Use
`STATIC` or `OBJECT` libraries.

## Make

### The rules

The explicit GNU make rules for the same three programs are the checked-in
[`examples/cmake/Makefile`](/examples/cmake/Makefile), quoted here verbatim;
`test.sh` builds it, so the two cannot drift. Run it from `examples/cmake` as
`make CARBON_TOOLCHAIN=<toolchain directory> all` (or `run`, which also runs the
programs; `O=<dir>` moves the outputs, `clean` removes them):

```make
# Toolchain directory: the unpacked tarball, the parent of bin/carbon.
ifeq ($(origin CARBON_TOOLCHAIN),undefined)
  ifeq ($(origin CARBON),undefined)
    $(error set CARBON_TOOLCHAIN=<toolchain directory> or CARBON=<path to bin/carbon>)
  endif
  CARBON_TOOLCHAIN := $(abspath $(dir $(CARBON))..)
endif
CARBON ?= $(CARBON_TOOLCHAIN)/bin/carbon
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
```

Rule by rule:

-   **The variable block.** `CARBON_TOOLCHAIN` is the toolchain directory;
    when only `CARBON` (a path to `bin/carbon`) is given, the directory is
    derived as its parent's parent, and with neither the Makefile stops at the
    `$(error)`. `CXX`, `CC` and `AR` are GNU make builtins with origin
    `default` (`make -p -f /dev/null` prints `CXX = g++`), which `?=` treats
    as already set — so `CXX` takes `:=`, which a command-line `make CXX=...`
    still overrides. With `CXX ?=`, `twice.o` is built by `g++` and the mixed
    link fails with `ld.lld: error: undefined symbol: std::cout`.
-   **`$(O)`** is the output directory. Every object rule lists it as an
    order-only prerequisite (`| $(O)`), so a fresh `O=` works on a clean tree
    and the source tree stays clean.
-   **`io.impl.o`** compiles both files of Core's `io` library with
    `--no-include-carbon-core` and keeps the last input's object, the impl's
    — the one with the bodies of `Core.PrintStr` and `Core.EOF`.
-   **`hello.o`** is a single-file compile; `--output-last-input-only` is
    harmless with one input.
-   **`hello`** links its object and `io.impl.o`; `carbon link` adds the
    prelude objects and the runtimes.
-   **`widget.impl.o` and `widget_main.o`** show the package rule: an
    object's prerequisites are every file of its package (and of the packages
    it imports), all of them on the command line, the target unit last. The
    API file's object is empty, so only the impl's and `main`'s are linked.
-   **`twice.o`** is compiled by the toolchain's drop-in `clang++`.
-   **`mixed.o`** passes the header directory as `--clang-arg=-Imixed` and
    lists `twice.h` as a prerequisite by hand, because the driver writes no
    dependency file.
-   **`mixed`** links the Carbon object and the C++ object together.

Objects go **before** the `--` on every `carbon link` line. The help text for
`link` says the Clang arguments after `--` may carry object files intermingled
with flags, but `carbon link --output=x -- a.o b.o -lc++` fails with
`error: no such file or directory: '-lc++'`; the positional form
`carbon link --output=x a.o b.o -- -lc++` links (W-133).

### The `carbon build` one-liner

For a throwaway build of a Carbon-only program, `carbon build` compiles every
file of the package into hashed temporary objects, links Core's `io` objects
itself, and names the output after the first input:

```shell
carbon build --output=widget_main widget/widget.carbon widget/widget.impl.carbon widget/main.carbon
```

Two caveats, both filed as W-133: the help text lists `.cpp` inputs, but a
`.cpp` positional is parsed as Carbon (`unrecognized declaration introducer`),
and C++ objects go after a second `--`; and the short output flag works only as
`-o=FILE` (`-o FILE` fails with "requires a value"). It produces no object a
library target can own and tracks no dependencies, so the explicit rules above
are the Make shape for anything beyond one program.

## Limits in 0.1

Each limit is a filed item in `fork/inventory/work-items.json`.

| Limit                                                                                                                                                                 | Item  |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `carbon compile` writes no dependency file for `import Cpp library` headers; `OBJECT_DEPENDS` (CMake) or an explicit prerequisite (Make) lists them by hand.         | W-129 |
| Every unit of a package re-parses the whole package; source-file properties are per directory, so a file is wired into one package per `CMakeLists.txt`.              | W-130 |
| `carbon link` adds no Core `io` objects; `Carbon::core_io` (or `io.impl.o`) is linked explicitly.                                                                      | W-003 |
| No shared libraries or modules: `SHARED` and `MODULE` Carbon targets fail at build time.                                                                              | W-132 |
| The modules are not installed into the toolchain tree and there is no `find_package(Carbon CONFIG)`; projects reach them through `CMAKE_MODULE_PATH`.                 | W-128 |
| Objects built by a system `g++` do not link under `carbon link`; the C++ half is compiled by the toolchain's `clang++`.                                               | W-131 |
| `carbon build` rejects `.cpp` inputs despite its help text, takes its short output flag only as `-o=FILE`, and `carbon link` rejects objects intermingled after `--`. | W-133 |
| `CMAKE_Carbon_COMPILER_TARGET` (cross-compiling) and `CMAKE_Carbon_COMPILER_LAUNCHER` are not wired; Windows is unsupported and macOS is unverified.                  | W-128 |
