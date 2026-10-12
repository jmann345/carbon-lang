# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Verify that the selected Carbon compiler can build a trivial program. CMake
# loads this module after CMakeCarbonInformation.cmake, as it does its own
# CMakeTest<LANG>Compiler modules.
if(CMAKE_Carbon_COMPILER_FORCED)
  # The compiler configuration was forced by the user; assume it works.
  set(CMAKE_Carbon_COMPILER_WORKS TRUE)
  return()
endif()

include(CMakeTestCompilerCommon)

# Remove any cached result from an earlier run so a changed compiler is
# re-tested.
unset(CMAKE_Carbon_COMPILER_WORKS CACHE)

if(NOT CMAKE_Carbon_COMPILER_WORKS)
  PrintTestCompilerStatus("Carbon")
  set(__CMAKE_Carbon_TEST_SOURCE "fn Run() -> i32 { return 0; }\n")
  try_compile(CMAKE_Carbon_COMPILER_WORKS
    SOURCE_FROM_VAR testCarbonCompiler.carbon __CMAKE_Carbon_TEST_SOURCE
    OUTPUT_VARIABLE __CMAKE_Carbon_COMPILER_OUTPUT)
  # Move the result from the cache to a normal variable.
  set(CMAKE_Carbon_COMPILER_WORKS ${CMAKE_Carbon_COMPILER_WORKS})
  unset(CMAKE_Carbon_COMPILER_WORKS CACHE)
  set(Carbon_TEST_WAS_RUN 1)
endif()

if(NOT CMAKE_Carbon_COMPILER_WORKS)
  PrintTestCompilerResult(CHECK_FAIL "broken")
  string(REPLACE "\n" "\n  " _output "${__CMAKE_Carbon_COMPILER_OUTPUT}")
  message(FATAL_ERROR "The Carbon compiler\n  \"${CMAKE_Carbon_COMPILER}\"\n"
    "is not able to compile a simple test program.\nIt fails "
    "with the following output:\n  ${_output}\n\n"
    "CMake will not be able to correctly generate this project.")
else()
  if(Carbon_TEST_WAS_RUN)
    PrintTestCompilerResult(CHECK_PASS "works")
  endif()
  # Re-configure the compiler file to record CMAKE_Carbon_COMPILER_WORKS.
  configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeCarbonCompiler.cmake.in
    ${CMAKE_PLATFORM_INFO_DIR}/CMakeCarbonCompiler.cmake @ONLY)
  include(${CMAKE_PLATFORM_INFO_DIR}/CMakeCarbonCompiler.cmake)
endif()
unset(__CMAKE_Carbon_TEST_SOURCE)
unset(__CMAKE_Carbon_COMPILER_OUTPUT)
