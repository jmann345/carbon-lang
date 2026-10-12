# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# An example project built with the Carbon toolchain through CMake's language
# support in /cmake (see /docs/guides/build_systems.md). It builds three
# programs: `hello` (one Carbon file), `widget_main` (a two-file Carbon
# package consumed through a static library) and `mixed` (Carbon calling C++
# compiled by the toolchain's own drop-in clang++).
cmake_minimum_required(VERSION 3.28)

# The toolchain directory (the unpacked tarball, the parent of bin/carbon)
# comes from the CARBON_TOOLCHAIN cache entry, else the environment variable
# of the same name, else `carbon` on PATH: bin/carbon is a symlink to
# lib/carbon/carbon-busybox, so its real path needs three steps up. This block
# must run BEFORE project(): it seeds the compilers, which cannot change
# afterwards. A user-set CMAKE_Carbon_COMPILER or CMAKE_CXX_COMPILER wins.
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
# The compilers seeded above are not cache entries, so CMake's own
# compiler-change detection never sees a changed CARBON_TOOLCHAIN: a build
# directory keeps the toolchain of its first configure. Refuse a mismatch
# rather than silently building with the old one.
if(DEFINED _CARBON_TOOLCHAIN_CONFIGURED
    AND NOT _CARBON_TOOLCHAIN_CONFIGURED STREQUAL CARBON_TOOLCHAIN)
  message(FATAL_ERROR
    "CARBON_TOOLCHAIN changed from '${_CARBON_TOOLCHAIN_CONFIGURED}' to "
    "'${CARBON_TOOLCHAIN}'; the compilers are fixed at the first configure. "
    "Use a fresh build directory (cmake --fresh ...).")
endif()
set(_CARBON_TOOLCHAIN_CONFIGURED "${CARBON_TOOLCHAIN}" CACHE INTERNAL
  "The CARBON_TOOLCHAIN this build directory was configured with")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake")
project(carbon_cmake_example LANGUAGES Carbon CXX)
include(CarbonTargets)

# Core's `io` library: `carbon link` adds only the prelude objects, so
# programs calling Core.PrintStr link this archive explicitly.
carbon_add_core_library(io)

# One Carbon file: plain add_executable works.
add_executable(hello hello/hello.carbon)
target_link_libraries(hello PRIVATE Carbon::core_io)

# A two-file package (API + impl) as a static library, consumed by another
# package: the helpers put the whole package on every compile line.
carbon_add_library(widget STATIC
  SOURCES widget/widget.carbon widget/widget.impl.carbon)
carbon_add_executable(widget_main SOURCES widget/main.carbon DEPS widget)
target_link_libraries(widget_main PRIVATE Carbon::core_io)

# Carbon importing a C++ header: the C++ half is an ordinary CXX library
# compiled by the toolchain's clang++; its PUBLIC include directory reaches
# the Carbon compile line as `--clang-arg=-I`. The header dependency is
# explicit (OBJECT_DEPENDS): `carbon compile` writes no depfile.
add_library(twice STATIC mixed/twice.cpp)
target_include_directories(twice PUBLIC mixed)
add_executable(mixed mixed/main.carbon)
set_source_files_properties(mixed/main.carbon PROPERTIES
  OBJECT_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/mixed/twice.h")
target_link_libraries(mixed PRIVATE twice)
