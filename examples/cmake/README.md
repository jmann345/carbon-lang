# CMake and Make example project

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

A small project built with an installed Carbon toolchain through the CMake
language support in [/cmake](/cmake/README.md), and again through the explicit
rules of the checked-in [`Makefile`](Makefile). It is the project the guide
[Build systems: CMake and Make](/docs/guides/build_systems.md) walks through,
and its `test.sh` is the arbiter the fork's conformance runner drives for the
two build-system milestone bullets.

Three programs:

| Program       | Sources                                                               | Shows                                                                                                                                                                           | Prints                                                      |
| ------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| `hello`       | `hello/hello.carbon`                                                  | One Carbon file through plain `add_executable`, linking `Carbon::core_io` for `Core.PrintStr`.                                                                                  | `built by CMake-integrated Carbon`                          |
| `widget_main` | `widget/widget.carbon`, `widget/widget.impl.carbon`, `widget/main.carbon` | A two-file package (API and impl) as a static library through `carbon_add_library`, consumed by `carbon_add_executable(... DEPS widget)`.                                       | `widget package built by CMake-integrated Carbon`, then `7` |
| `mixed`       | `mixed/main.carbon`, `mixed/twice.h`, `mixed/twice.cpp`               | Carbon importing a C++ header; the C++ half is compiled by the toolchain's drop-in `clang++` and the whole program is linked by `carbon link`.                                   | `built by a drop-in Clang build-system example`, then `42`  |

## Building

Unpack a nightly toolchain and point `CARBON_TOOLCHAIN` at the unpacked
directory (the parent of `bin/carbon`). The quickest check builds the project
three ways and compares the programs' output:

```shell
CARBON_TOOLCHAIN=/path/to/carbon_toolchain-<version> examples/cmake/test.sh
```

By hand with CMake, from the repository root:

```shell
cmake -S examples/cmake -B build -DCARBON_TOOLCHAIN=/path/to/carbon_toolchain-<version>
cmake --build build
build/hello && build/widget_main && build/mixed
```

Add `-G Ninja` to the first command for the Ninja generator. Without
`CARBON_TOOLCHAIN`, the `CMakeLists.txt` resolves `carbon` from `PATH`; a
user-set `CMAKE_Carbon_COMPILER` or `CMAKE_CXX_COMPILER` always wins.

With the Makefile, from this directory:

```shell
make CARBON_TOOLCHAIN=/path/to/carbon_toolchain-<version> run
```

Objects and programs go under `build-make/` (override with `O=<dir>`); `make
clean` removes them. The Makefile needs either `CARBON_TOOLCHAIN` or `CARBON`
(a path to `bin/carbon`) and stops with a message otherwise.

## test.sh

`test.sh [--build-dir DIR] [--only TARGET]... [--no-ninja] [--no-make]`
configures and builds the project with the Unix Makefiles generator, with the
Ninja generator when `ninja` is on `PATH`, and with the Makefile; runs the
selected programs from each build; requires the outputs to be byte-identical;
and prints the Unix Makefiles build's program output on stdout, with every
other message on stderr. The toolchain comes from `CARBON_TOOLCHAIN`, else
`CARBON`, else `carbon` on `PATH`; the build directory from `--build-dir`, else
`CARBON_BUILD_DIR`, else a fresh temporary directory. Exit codes: 0 success, 2
configure or compile failed, 3 link failed, 4 a program failed, 5 the variants
disagree, 64 usage, 66 toolchain not found.

## Limits in this release

Each is a filed fork ledger item (`fork/inventory/work-items.json`); the guide's
"Limits" section has the details.

-   `carbon compile` writes no dependency file, so header dependencies of
    `import Cpp library` units are listed by hand in `OBJECT_DEPENDS` (W-129).
-   Every unit of a package re-parses the whole package, and a source file can
    be wired into one package per CMake directory (W-130).
-   `carbon link` adds only the prelude objects; programs using `Core.PrintStr`
    link `Carbon::core_io` explicitly (W-003).
-   Shared libraries are not supported: a `SHARED` or `MODULE` Carbon target
    fails at build time (W-132).
-   The modules are not installed into the toolchain tree; there is no
    `find_package(Carbon)` (W-128).
-   Objects built by a system `g++` do not link under `carbon link` (W-131).
-   `carbon build` rejects `.cpp` inputs despite its help text and takes its
    short output flag only as `-o=FILE` (W-133).
