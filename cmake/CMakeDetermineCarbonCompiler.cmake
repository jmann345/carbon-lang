# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Determine the compiler to use for Carbon sources.
#
# CMake loads this module (found through CMAKE_MODULE_PATH) when `project()`
# or `enable_language()` names Carbon and CMAKE_Carbon_COMPILER_LOADED is not
# yet set, in the same way it loads its own CMakeDetermine<LANG>Compiler
# modules. The structure mirrors CMake's CMakeDetermineASMCompiler.cmake:
# the environment-variable and cache-entry lookup, `_cmake_find_compiler`
# over a candidate list, vendor-regex identification without a compiler-id
# source file, the CMakeFindBinUtils pass and the final `configure_file` of
# the per-language compiler file.
#
# Discovery order (fork/cmake/plan.md, D-CM-3):
#   1. the CMAKE_Carbon_COMPILER cache entry (a list splits into the
#      compiler and CMAKE_Carbon_COMPILER_ARG1);
#   2. the CARBON environment variable;
#   3. `carbon` or `carbon-busybox` on PATH.
include(${CMAKE_ROOT}/Modules/CMakeDetermineCompiler.cmake)

if(NOT CMAKE_Carbon_COMPILER)
  set(CMAKE_Carbon_COMPILER_INIT NOTFOUND)
  # Prefer the environment variable CARBON (the ASM/SWIFTC handling).
  if(NOT $ENV{CARBON} STREQUAL "")
    get_filename_component(CMAKE_Carbon_COMPILER_INIT $ENV{CARBON}
      PROGRAM PROGRAM_ARGS CMAKE_Carbon_FLAGS_ENV_INIT)
    if(CMAKE_Carbon_FLAGS_ENV_INIT)
      set(CMAKE_Carbon_COMPILER_ARG1 "${CMAKE_Carbon_FLAGS_ENV_INIT}"
        CACHE STRING "Arguments to the Carbon compiler")
    endif()
    if(NOT EXISTS ${CMAKE_Carbon_COMPILER_INIT})
      message(FATAL_ERROR
        "Could not find compiler set in environment variable CARBON:\n"
        "$ENV{CARBON}.")
    endif()
  endif()
  if(NOT CMAKE_Carbon_COMPILER_INIT)
    set(CMAKE_Carbon_COMPILER_LIST carbon carbon-busybox)
  endif()
  _cmake_find_compiler(Carbon)
else()
  _cmake_find_compiler_path(Carbon)
endif()
mark_as_advanced(CMAKE_Carbon_COMPILER)

if(NOT CMAKE_Carbon_COMPILER)
  message(FATAL_ERROR
    "Could not find the Carbon toolchain driver `carbon`. Name it in one of "
    "three ways: set the cache entry CMAKE_Carbon_COMPILER "
    "(-DCMAKE_Carbon_COMPILER=<toolchain directory>/bin/carbon), export "
    "CARBON=<toolchain directory>/bin/carbon in the environment, or put the "
    "toolchain's bin/ directory on PATH.")
endif()

if(NOT _CMAKE_TOOLCHAIN_LOCATION)
  get_filename_component(_CMAKE_TOOLCHAIN_LOCATION "${CMAKE_Carbon_COMPILER}"
    PATH)
endif()

# Identify the compiler from the output of `carbon version`; no compiler-id
# source file is compiled (the mechanism CMakeDetermineASMCompiler uses for
# assemblers). The version line is
#   Carbon Language toolchain version: 0.0.0-0.nightly.YYYY.MM.DD+<sha>
# and the captured group becomes CMAKE_Carbon_COMPILER_VERSION.
if(NOT CMAKE_Carbon_COMPILER_ID)
  set(CMAKE_Carbon_COMPILER_ID_VENDORS Carbon)
  set(CMAKE_Carbon_COMPILER_ID_VENDOR_FLAGS_Carbon "version")
  set(CMAKE_Carbon_COMPILER_ID_VENDOR_REGEX_Carbon
    "Carbon Language toolchain version: ([0-9][^ \r\n]*)")
  include(${CMAKE_ROOT}/Modules/CMakeDetermineCompilerId.cmake)
  CMAKE_DETERMINE_COMPILER_ID_VENDOR(Carbon "")
  if(CMAKE_Carbon_COMPILER_ID_VENDOR_MATCH)
    set(CMAKE_Carbon_COMPILER_VERSION "${CMAKE_Carbon_COMPILER_ID_VENDOR_MATCH}")
  endif()
  unset(CMAKE_Carbon_COMPILER_ID_OUTPUT)
endif()
if(CMAKE_Carbon_COMPILER_ID)
  message(STATUS "The Carbon compiler identification is "
    "${CMAKE_Carbon_COMPILER_ID} ${CMAKE_Carbon_COMPILER_VERSION}")
else()
  message(STATUS "The Carbon compiler identification is unknown")
endif()

# The install layout, from `carbon config --json`. INSTALL_ROOT is the
# install root (`<toolchain directory>/lib/carbon/`, where core/ lives) and
# LLVM_BINDIR holds the toolchain's own LLVM tools. Each read is guarded so a
# future nightly without one of the keys still configures, with the value
# empty.
execute_process(COMMAND "${CMAKE_Carbon_COMPILER}" config --json
  OUTPUT_VARIABLE _carbon_config_json
  RESULT_VARIABLE _carbon_config_result
  ERROR_QUIET)
if(_carbon_config_result EQUAL 0)
  string(JSON CMAKE_Carbon_INSTALL_ROOT ERROR_VARIABLE _carbon_json_error
    GET "${_carbon_config_json}" INSTALL_ROOT)
  if(_carbon_json_error)
    set(CMAKE_Carbon_INSTALL_ROOT "")
  endif()
  string(JSON CMAKE_Carbon_LLVM_BINDIR ERROR_VARIABLE _carbon_json_error
    GET "${_carbon_config_json}" LLVM_BINDIR)
  if(_carbon_json_error)
    set(CMAKE_Carbon_LLVM_BINDIR "")
  endif()
  unset(_carbon_json_error)
endif()
unset(_carbon_config_json)
unset(_carbon_config_result)

# The toolchain's own binutils (what `carbon llvm ar` and `carbon llvm
# ranlib` run); recorded for information, advanced.
find_program(CMAKE_Carbon_COMPILER_AR NAMES llvm-ar
  HINTS "${CMAKE_Carbon_LLVM_BINDIR}" NO_DEFAULT_PATH
  DOC "LLVM archiver shipped with the Carbon toolchain")
find_program(CMAKE_Carbon_COMPILER_RANLIB NAMES llvm-ranlib
  HINTS "${CMAKE_Carbon_LLVM_BINDIR}" NO_DEFAULT_PATH
  DOC "LLVM ranlib shipped with the Carbon toolchain")
mark_as_advanced(CMAKE_Carbon_COMPILER_AR CMAKE_Carbon_COMPILER_RANLIB)

# Generic CMAKE_AR / CMAKE_RANLIB / CMAKE_LINKER discovery, as every
# CMakeDetermine<LANG>Compiler module does.
set(_CMAKE_PROCESSING_LANGUAGE "Carbon")
include(CMakeFindBinUtils)
unset(_CMAKE_PROCESSING_LANGUAGE)

set(CMAKE_Carbon_COMPILER_ENV_VAR "CARBON")

# Persist what was learned so later runs and try_compile projects skip
# detection.
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeCarbonCompiler.cmake.in
  ${CMAKE_PLATFORM_INFO_DIR}/CMakeCarbonCompiler.cmake @ONLY)
