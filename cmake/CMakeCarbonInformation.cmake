# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Rule variables and flags for the Carbon language. CMake loads this module
# after CMakeCarbonCompiler.cmake and CMakeSystemSpecificInformation.cmake.
set(CMAKE_Carbon_OUTPUT_EXTENSION .o)

# Include directories and definitions reach the Clang embedded in the Carbon
# toolchain, which resolves `import Cpp library "<header>"`.
set(CMAKE_INCLUDE_FLAG_Carbon "--clang-arg=-I")
set(CMAKE_Carbon_DEFINE_FLAG "--clang-arg=-D")

# Optional per-compiler and per-platform overrides, also found on
# CMAKE_MODULE_PATH.
if(CMAKE_Carbon_COMPILER_ID)
  include(Compiler/${CMAKE_Carbon_COMPILER_ID}-Carbon OPTIONAL)
  include(
    Platform/${CMAKE_EFFECTIVE_SYSTEM_NAME}-${CMAKE_Carbon_COMPILER_ID}-Carbon
    OPTIONAL)
endif()

# Everything after `--` on the `carbon link` line is Clang-driver syntax.
set(CMAKE_Carbon_LIBRARY_PATH_FLAG "-L")
set(CMAKE_Carbon_LINK_LIBRARY_FLAG "-l")
set(CMAKE_Carbon_LINKER_WRAPPER_FLAG "-Wl,")
set(CMAKE_Carbon_LINKER_WRAPPER_FLAG_SEP ",")
set(CMAKE_Carbon_RESPONSE_FILE_LINK_FLAG "@")
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(CMAKE_SHARED_LIBRARY_RUNTIME_Carbon_FLAG "-Wl,-rpath,")
  set(CMAKE_SHARED_LIBRARY_RUNTIME_Carbon_FLAG_SEP ":")
  set(CMAKE_SHARED_LIBRARY_RPATH_LINK_Carbon_FLAG "-Wl,-rpath-link,")
endif()
if(NOT CMAKE_EXECUTABLE_RUNTIME_Carbon_FLAG)
  set(CMAKE_EXECUTABLE_RUNTIME_Carbon_FLAG
    ${CMAKE_SHARED_LIBRARY_RUNTIME_Carbon_FLAG})
endif()
if(NOT CMAKE_EXECUTABLE_RUNTIME_Carbon_FLAG_SEP)
  set(CMAKE_EXECUTABLE_RUNTIME_Carbon_FLAG_SEP
    ${CMAKE_SHARED_LIBRARY_RUNTIME_Carbon_FLAG_SEP})
endif()
if(NOT CMAKE_EXECUTABLE_RPATH_LINK_Carbon_FLAG)
  set(CMAKE_EXECUTABLE_RPATH_LINK_Carbon_FLAG
    ${CMAKE_SHARED_LIBRARY_RPATH_LINK_Carbon_FLAG})
endif()

# CMAKE_Carbon_FLAGS and its per-configuration variants are cache entries;
# the default flags are seeded from the CARBONFLAGS environment variable and
# the per-configuration defaults map onto `carbon compile`'s optimization
# levels (`--optimize=none|debug|speed|size`) and `--no-debug-info`.
set(CMAKE_Carbon_FLAGS_INIT "$ENV{CARBONFLAGS} ${CMAKE_Carbon_FLAGS_INIT}")
set(CMAKE_Carbon_FLAGS_DEBUG_INIT "--optimize=none")
set(CMAKE_Carbon_FLAGS_RELEASE_INIT "--optimize=speed --no-debug-info")
set(CMAKE_Carbon_FLAGS_RELWITHDEBINFO_INIT "--optimize=speed")
set(CMAKE_Carbon_FLAGS_MINSIZEREL_INIT "--optimize=size --no-debug-info")
cmake_initialize_per_config_variable(CMAKE_Carbon_FLAGS
  "Flags used by the Carbon compiler")

# Seeds the linker-flag variables (CMAKE_EXE_LINKER_FLAGS and friends) from
# LDFLAGS, as every language does.
include(CMakeCommonLanguageInclude)

# One object per source. The driver writes only one object per invocation,
# the one for its LAST input, and `--output-last-input-only` is in the rule
# itself (it is silent for a single input) so that per-source COMPILE_OPTIONS
# can carry the other files of a package before <SOURCE> — the whole-package
# model of CarbonTargets.cmake. <FLAGS> precede the source for that reason.
if(NOT CMAKE_Carbon_COMPILE_OBJECT)
  set(CMAKE_Carbon_COMPILE_OBJECT
    "<CMAKE_Carbon_COMPILER> compile <DEFINES> <INCLUDES> <FLAGS> --output-last-input-only --output=<OBJECT> <SOURCE>")
endif()

# `carbon link` adds the prelude objects and the runtimes itself. <FLAGS> is
# deliberately omitted: CMAKE_Carbon_FLAGS are `compile` options, not `link`
# options. Objects stay positional before `--`; the driver rejects objects
# intermingled with Clang flags after it.
if(NOT CMAKE_Carbon_LINK_EXECUTABLE)
  set(CMAKE_Carbon_LINK_EXECUTABLE
    "<CMAKE_Carbon_COMPILER> link <CMAKE_Carbon_LINK_FLAGS> --output=<TARGET> <OBJECTS> -- <LINK_FLAGS> <LINK_LIBRARIES>")
endif()

# Static archives through the ordinary archiver: Carbon objects are plain ELF
# objects, so the system `ar` and `llvm-ar` both work.
if(NOT DEFINED CMAKE_Carbon_ARCHIVE_CREATE)
  set(CMAKE_Carbon_ARCHIVE_CREATE "<CMAKE_AR> qc <TARGET> <LINK_FLAGS> <OBJECTS>")
endif()
if(NOT DEFINED CMAKE_Carbon_ARCHIVE_APPEND)
  set(CMAKE_Carbon_ARCHIVE_APPEND "<CMAKE_AR> q <TARGET> <LINK_FLAGS> <OBJECTS>")
endif()
if(NOT DEFINED CMAKE_Carbon_ARCHIVE_FINISH)
  set(CMAKE_Carbon_ARCHIVE_FINISH "<CMAKE_RANLIB> <TARGET>")
endif()

# Shared libraries and modules are not supported: `carbon link` has no
# shared-library mode (its help text carries the TODO; fork ledger item
# W-132). The rules are a command that always fails, so a SHARED or MODULE
# target configures and then fails at build time under every generator.
# Leaving the variables undefined is not enough: only the Makefiles generator
# reports "required internal CMake variable not set" at generate time, while
# the Ninja generator emits a rule whose command is `$PRE_LINK && $POST_BUILD`
# (`: && :`), prints "Linking Carbon shared library" and exits 0 without
# writing the library (measured with CMake 3.28.3).
set(CMAKE_Carbon_CREATE_SHARED_LIBRARY "<CMAKE_COMMAND> -E false")
set(CMAKE_Carbon_CREATE_SHARED_MODULE "<CMAKE_COMMAND> -E false")

set(CMAKE_Carbon_INFORMATION_LOADED 1)
