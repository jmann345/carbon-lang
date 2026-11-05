# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Helpers that express Carbon's whole-package compile model on top of CMake's
# object-per-source rule.
#
# The driver demands every file of a package on one `carbon compile` command
# line (a unit compiled alone cannot see its package's API or impl files),
# while CMake compiles one <SOURCE> per rule. These functions reconcile the
# two the way the Bazel rules do (bazel/carbon_rules/defs.bzl): every
# object's command line carries all sibling files of its package plus the API
# files of the packages it depends on, the object is the LAST input (the
# compile rule in CMakeCarbonInformation.cmake passes
# `--output-last-input-only`), and OBJECT_DEPENDS makes the object rebuild
# when any of those files changes.
#
#   carbon_add_library(<name> [STATIC|OBJECT] SOURCES <files...>
#                      [DEPS <carbon libraries...>] [NO_CORE])
#   carbon_add_executable(<name> SOURCES <files...>
#                         [DEPS <carbon libraries...>])
#   carbon_add_core_library(<lib>)
#
# A library publishes its API files (every source not ending in
# `.impl.carbon`) plus its dependencies' through the target property
# CARBON_API_FILES; a consumer's DEPS puts them on its compile lines and links
# the archive. Every unit of a package re-parses the whole package (ledger
# item W-130).
include_guard(GLOBAL)

# Wires the package of `target`: per-source COMPILE_OPTIONS and OBJECT_DEPENDS
# carrying the dependency API files and the package's other files, and the
# target's CARBON_API_FILES.
function(_carbon_wire_package target)
  cmake_parse_arguments(ARG "NO_CORE" "" "SOURCES;DEPS" ${ARGN})
  set(all_files)
  set(api_files)
  foreach(src IN LISTS ARG_SOURCES)
    get_filename_component(abs "${src}" ABSOLUTE)
    list(APPEND all_files "${abs}")
    if(NOT abs MATCHES "\\.impl\\.carbon$")
      list(APPEND api_files "${abs}")
    endif()
  endforeach()
  set(dep_apis)
  foreach(dep IN LISTS ARG_DEPS)
    if(NOT TARGET ${dep})
      message(FATAL_ERROR
        "${target}: DEPS names `${dep}`, which is not a target; Carbon "
        "dependencies must be created by carbon_add_library first.")
    endif()
    get_target_property(d ${dep} CARBON_API_FILES)
    if(d)
      list(APPEND dep_apis ${d})
    endif()
  endforeach()
  set(extra)
  if(ARG_NO_CORE)
    set(extra "--no-include-carbon-core")
  endif()
  foreach(src IN LISTS all_files)
    # Source-file properties are per directory: a file wired into two
    # packages from one CMakeLists.txt would receive both sibling lists.
    # Refuse that instead of generating a wrong command line.
    get_property(owner SOURCE "${src}" PROPERTY CARBON_PACKAGE)
    if(owner AND NOT owner STREQUAL target)
      message(FATAL_ERROR
        "${src} already belongs to the Carbon package of target `${owner}` "
        "and cannot also be a source of `${target}`: source-file properties "
        "are per directory, so one file can be wired into one package per "
        "CMakeLists.txt. Build it as an OBJECT library and consume "
        "$<TARGET_OBJECTS:${owner}> instead.")
    endif()
    set_property(SOURCE "${src}" PROPERTY CARBON_PACKAGE ${target})
    set(others ${dep_apis} ${all_files})
    list(REMOVE_ITEM others "${src}")
    set_property(SOURCE "${src}" TARGET_DIRECTORY ${target} APPEND PROPERTY
      COMPILE_OPTIONS ${extra} ${others})
    set_property(SOURCE "${src}" TARGET_DIRECTORY ${target} APPEND PROPERTY
      OBJECT_DEPENDS ${others})
  endforeach()
  set_target_properties(${target} PROPERTIES
    CARBON_API_FILES "${api_files};${dep_apis}")
endfunction()

# carbon_add_library(<name> [STATIC|OBJECT] SOURCES <package files...>
#                    [DEPS <carbon libraries...>] [NO_CORE])
#
# A STATIC (default) or OBJECT library holding one Carbon package. DEPS are
# other Carbon libraries: their API files reach this package's compile lines
# and they are linked PUBLIC. NO_CORE passes `--no-include-carbon-core`, which
# is only right for the Core package's own sources (carbon_add_core_library).
function(carbon_add_library name)
  cmake_parse_arguments(ARG "STATIC;OBJECT;NO_CORE" "" "SOURCES;DEPS" ${ARGN})
  if(NOT ARG_SOURCES)
    message(FATAL_ERROR "carbon_add_library(${name}): SOURCES is required")
  endif()
  set(kind STATIC)
  if(ARG_OBJECT)
    set(kind OBJECT)
  endif()
  add_library(${name} ${kind} ${ARG_SOURCES})
  set(nocore)
  if(ARG_NO_CORE)
    set(nocore NO_CORE)
  endif()
  _carbon_wire_package(${name} SOURCES ${ARG_SOURCES} DEPS ${ARG_DEPS}
    ${nocore})
  if(ARG_DEPS)
    target_link_libraries(${name} PUBLIC ${ARG_DEPS})
  endif()
endfunction()

# carbon_add_executable(<name> SOURCES <package files...>
#                       [DEPS <carbon libraries...>])
#
# An executable whose sources form one Carbon package (the `Main` package
# with its `Run` entry point). DEPS are linked PRIVATE.
function(carbon_add_executable name)
  cmake_parse_arguments(ARG "" "" "SOURCES;DEPS" ${ARGN})
  if(NOT ARG_SOURCES)
    message(FATAL_ERROR "carbon_add_executable(${name}): SOURCES is required")
  endif()
  add_executable(${name} ${ARG_SOURCES})
  _carbon_wire_package(${name} SOURCES ${ARG_SOURCES} DEPS ${ARG_DEPS})
  if(ARG_DEPS)
    target_link_libraries(${name} PRIVATE ${ARG_DEPS})
  endif()
endfunction()

# carbon_add_core_library(<lib>)
#
# Builds the Core library <lib> (for example `io`) from the toolchain's own
# sources under `${CMAKE_Carbon_INSTALL_ROOT}/core/` as the STATIC target
# `carbon_core_<lib>` with the alias `Carbon::core_<lib>`. The library's files
# are the entries of core/core_library_manifest.txt named `<lib>.carbon` and
# `<lib>.impl.carbon`; a library the manifest does not list is an error.
#
# Needed because `carbon link` adds only the prelude objects, not the rest of
# Core (toolchain/driver/link_driver.cpp's TODO; ledger item W-003): a program
# calling `Core.PrintStr` or `Core.EOF` links `Carbon::core_io` explicitly.
function(carbon_add_core_library lib)
  if(NOT CMAKE_Carbon_INSTALL_ROOT)
    message(FATAL_ERROR
      "carbon_add_core_library(${lib}): CMAKE_Carbon_INSTALL_ROOT is empty; "
      "`carbon config --json` did not report INSTALL_ROOT.")
  endif()
  set(core "${CMAKE_Carbon_INSTALL_ROOT}/core")
  set(manifest "${core}/core_library_manifest.txt")
  if(NOT EXISTS "${manifest}")
    message(FATAL_ERROR
      "carbon_add_core_library(${lib}): ${manifest} not found in the "
      "toolchain's install root.")
  endif()
  file(STRINGS "${manifest}" entries)
  set(srcs)
  foreach(entry IN LISTS entries)
    if(entry STREQUAL "${lib}.carbon" OR entry STREQUAL "${lib}.impl.carbon")
      list(APPEND srcs "${core}/${entry}")
    endif()
  endforeach()
  if(NOT srcs)
    message(FATAL_ERROR
      "carbon_add_core_library(${lib}): Core library `${lib}` is not listed "
      "in ${manifest}; its entries are: ${entries}")
  endif()
  string(REPLACE "/" "_" lib_id "${lib}")
  carbon_add_library(carbon_core_${lib_id} STATIC SOURCES ${srcs} NO_CORE)
  add_library(Carbon::core_${lib_id} ALIAS carbon_core_${lib_id})
endfunction()
