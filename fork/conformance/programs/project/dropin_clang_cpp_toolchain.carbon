// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: toolchain drop-in usage as Clang C++ toolchain with common Make/CMake build systems
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   drop-in Clang C++ toolchain 42
//
// Working slice of this PARTIAL bullet: the installed toolchain IS a working
// Clang C++ toolchain. The install tree's lib/carbon/llvm/bin/{clang,
// clang++, clang-cl, clang-cpp, ld.lld, ...} are argv[0] symlinks to the
// carbon-busybox (toolchain/install/busybox_main.cpp maps `clang++` to
// `clang --driver-mode=g++`); toolchain/install/busybox_info_test.cpp and
// install_test.py (test_clang, test_clangplusplus, test_clang_cl,
// test_clang_cpp, run_cpp_test) integration-test those entry points,
// including compiling and running a C++ program with the clang++ symlink.
// The harness only drives `carbon compile`/`carbon link` on this file, so
// this program exercises the same machinery the symlinks dispatch to: the
// in-process Clang (toolchain/driver/clang_runner.cpp) must compile a real
// C++ TU — the `import Cpp inline` block below includes a std header from
// the bundled libc++ headers and defines a C++ function that streams to
// std::cout — and the link step must link it against the on-demand-built
// C++ runtimes (std::cout only resolves if the toolchain's own libc++
// links). Verified by hand against this exact install tree (nightly
// 2026.07.19): the clang++ symlink compiled, linked, and ran a std::cout
// hello world invoked directly, via `make` (CXX=<symlink>), and via CMake
// (-DCMAKE_CXX_COMPILER=<symlink>; configure detects "clang version
// 23.0.0git" and the build runs). The missing in-repo Make/CMake
// integration slice is encoded in the sibling SKIP program
// dropin_clang_make_cmake.carbon. Syntax evidence: `import Cpp inline`
// verbatim from check/testdata/interop/cpp/basics/inline/import.carbon and
// programs/interop/cpp_type_import_class_enum.carbon; C++-side std::cout
// from toolchain/install/install_test.py (run_cpp_test).

import Cpp inline '''
#include <iostream>

inline int EmitFromCpp(int n) {
  std::cout << "drop-in Clang C++ toolchain " << n << std::endl;
  return n - 42;
}
''';

fn Run() -> i32 {
  return Cpp.EmitFromCpp(42);
}
