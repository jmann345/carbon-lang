// CONFORMANCE-BULLET: Project: toolchain drop-in usage as Clang C++ toolchain with common Make/CMake build systems
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   built by a drop-in Clang build-system example
// SKIP: known-missing slice — Make/CMake integration of the drop-in Clang mode is unexercised and undocumented in-repo: the 0.1 arbiter (fork/gap-analysis.md, "Project/toolchain product features" section) requires a CI-tested example CMake project building a mixed Carbon/C++ program with the installed toolchain plus written Make-integration docs, and neither exists (no CMakeLists.txt or Makefile example anywhere; examples/bazel/ is the only downstream build-system example, and docs/ has no Make/CMake guide). This harness also cannot arbitrate it: runner.py only runs `carbon compile`/`carbon link` on single Main//default .carbon files and cannot drive an external build system. The underlying functionality does work when driven by hand against this exact install tree (nightly 2026.07.19): lib/carbon/llvm/bin/clang++ built and ran a std::cout C++ hello world both via `make` with CXX=<symlink> and via `cmake -DCMAKE_CXX_COMPILER=<symlink>` + `cmake --build` (configure detects "clang version 23.0.0git"), each printing the expected line with exit 0 — so the gap is in-repo integration, CI coverage, and documentation, not the drop-in toolchain itself. Un-SKIP (and move the arbitration to that example's CI) when the CMake example project and Make docs land.
//
// Body below is the Carbon half such a mixed Carbon/C++ CMake/Make example
// would build (the shape install_test.py's test_carbon_end_to_end compiles
// and links against the installed tree); kept valid so the program can be
// promoted when the integration slice lands.

import Cpp library "<iostream>";

fn Run() -> i32 {
  Cpp.std.cout << "built by a drop-in Clang build-system example\n";
  return 0;
}
