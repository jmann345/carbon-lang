// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: CMake build-system integration plus Make documentation
// BUILD-SCRIPT: examples/cmake/test.sh
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   built by CMake-integrated Carbon
//   widget package built by CMake-integrated Carbon
//   7
//   built by a drop-in Clang build-system example
//   42
//
// Un-SKIPped by the CM-1 landing (fork/cmake/plan.md §3, commit 2 of 3) on
// nightly 0.0.0-0.nightly.2026.10.12+62f1cc6: the arbiter is
// examples/cmake/test.sh, which configures and builds examples/cmake under
// the Unix Makefiles generator, the Ninja generator (when ninja is on PATH)
// and the checked-in Makefile with the CMake language modules of cmake/,
// runs hello, widget_main and mixed from each build, requires the outputs to
// be byte-identical and prints the Unix Makefiles build's output — the five
// lines above (hand-derived: the two Core.PrintStr literals, Get() returning
// the literal 7 through Core.Print, the C++ marker, Twice(21) = 42).
//
// The runner does NOT compile this file; the body below is
// examples/cmake/hello/hello.carbon verbatim after its license header, and
// `--self-test`'s identity rule fails if the two drift.

import Core library "io";

fn Run() -> i32 {
  Core.PrintStr("built by CMake-integrated Carbon\n");
  return 0;
}
