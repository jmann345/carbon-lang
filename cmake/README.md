# CMake language support for Carbon

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

This directory makes `.carbon` sources a first-class CMake language, built with
an installed Carbon toolchain (the nightly tarball). It holds the four modules
CMake looks up for a language it does not know itself, plus one helper file:

| File                                   | Role                                                                                                                                                                                               |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CMakeDetermineCarbonCompiler.cmake`   | Finds `carbon` (the `CMAKE_Carbon_COMPILER` cache entry, the `CARBON` environment variable, then `PATH`), identifies it from `carbon version`, and reads the install layout from `carbon config --json`. |
| `CMakeCarbonCompiler.cmake.in`         | The per-build compiler file CMake writes into `CMakeFiles/<version>/`.                                                                                                                             |
| `CMakeCarbonInformation.cmake`         | The compile, link and archive rules, the include and define flags, and the per-configuration flag defaults.                                                                                       |
| `CMakeTestCarbonCompiler.cmake`        | The `try_compile` of a one-line program that proves the compiler works.                                                                                                                            |
| `CarbonTargets.cmake`                  | `carbon_add_library`, `carbon_add_executable` and `carbon_add_core_library`: whole-package compilation on top of CMake's one-object-per-source rule, and the Core `io` library as a target.       |

## Using it

Put this directory on `CMAKE_MODULE_PATH` before `project()` and name the
language:

```cmake
cmake_minimum_required(VERSION 3.28)
list(APPEND CMAKE_MODULE_PATH "<path to this checkout>/cmake")
project(my_project LANGUAGES Carbon)
include(CarbonTargets)

carbon_add_core_library(io)
add_executable(hello hello.carbon)
target_link_libraries(hello PRIVATE Carbon::core_io)
```

CMake finds the toolchain through the `CMAKE_Carbon_COMPILER` cache entry
(`-DCMAKE_Carbon_COMPILER=<toolchain directory>/bin/carbon`), the `CARBON`
environment variable, or `carbon` on `PATH`. A mixed Carbon and C++ project
also names `CXX` and should point `CMAKE_CXX_COMPILER` at the toolchain's own
`lib/carbon/llvm/bin/clang++`; the example project shows the pattern.

The user guide is `docs/guides/build_systems.md` (Build systems: CMake and Make)
and the worked example is [examples/cmake](/examples/cmake/README.md), which
builds a single-file program, a two-file package behind a static library, and a
Carbon program calling C++ under the Unix Makefiles generator, the Ninja
generator and a plain Makefile.

## Installation

The modules are not yet installed into the toolchain tree, so there is no
`find_package(Carbon CONFIG)`; a project reaches them through
`CMAKE_MODULE_PATH` as above. Installing them beside the Bazel files under
`lib/carbon/` with a `CarbonConfig.cmake` is fork ledger item W-128
(`fork/inventory/work-items.json`).
