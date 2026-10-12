// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: toolchain drop-in usage as Clang C++ toolchain with common Make/CMake build systems
// BUILD-SCRIPT: examples/cmake/test.sh --only mixed
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   built by a drop-in Clang build-system example
//   42
//
// Un-SKIPped by the CM-1 landing (fork/cmake/plan.md §3, commit 2 of 3) on
// nightly 0.0.0-0.nightly.2026.10.12+62f1cc6: the arbiter is
// examples/cmake/test.sh --only mixed, which builds the mixed Carbon/C++
// program of examples/cmake three ways (CMake with the Unix Makefiles and
// Ninja generators, the checked-in Makefile) with the C++ half compiled by
// the toolchain's drop-in lib/carbon/llvm/bin/clang++ (CMAKE_CXX_COMPILER
// under CMake, `CXX :=` under Make) and the whole program linked by
// `carbon link`, then runs it from each build and requires the outputs to
// agree. The marker line is printed by C++ (std::cout in mixed/twice.cpp);
// 42 is Core.Print(Cpp.Twice(21)) from Carbon.
//
// Body replacement, disclosed (plan §0.2 item 6): the stub's body printed
// the marker from Carbon through `import Cpp library "<iostream>"`; the
// un-SKIPped body is examples/cmake/mixed/main.carbon verbatim after its
// license header, so the program IS the file the script builds
// (`--self-test`'s identity rule). The runner does NOT compile this file.

import Core library "io";
import Cpp library "twice.h";

fn Run() -> i32 {
  Cpp.PrintMarker();
  Core.Print(Cpp.Twice(21));
  return 0;
}
