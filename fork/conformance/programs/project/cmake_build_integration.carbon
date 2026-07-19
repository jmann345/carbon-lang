// CONFORMANCE-BULLET: Project: CMake build-system integration plus Make documentation
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   built by CMake-integrated Carbon
// SKIP: MISSING — no CMake support, example, or docs exist anywhere in the repo (only a libc++ header-expansion .bzl mentions cmake); Bazel is the only integrated build system. Distinct from the drop-in-Clang bullet (project/dropin_clang_make_cmake.carbon): this bullet requires first-class CMake integration for building *Carbon* code (a language/toolchain module or find-package flow driving `carbon compile`/`carbon link` from CMakeLists.txt) plus written Make documentation, none of which exists. This harness also cannot arbitrate it — runner.py only runs single .carbon files and cannot drive an external build system — so when the integration lands, arbitration must move to the example project's own CI; un-SKIP then.
//
// Write-tests-first stub. Intended future arbitration (sketched, since no
// single-file program can prove build-system integration):
//
//   # CMakeLists.txt of the future in-repo example project:
//   #   cmake_minimum_required(VERSION 3.28)
//   #   project(hello_carbon LANGUAGES Carbon)          # or find_package(Carbon)
//   #   add_executable(hello cmake_build_integration.carbon)
//   # plus a documented Make equivalent invoking `carbon compile` +
//   # `carbon link` explicitly, per the required Make documentation.
//
// The Carbon body below is the program such an example would build; it is
// valid today (Core.Print shape from stdlib/fundamental_types.carbon) so
// the file is promotable into the example project the day CMake
// integration lands. The EXPECT directives describe that future build's
// run; a premature un-SKIP here fails loudly on OUTPUT-MISMATCH because
// this body prints an integer, not the expected marker line.

import Core library "io";

fn Run() -> i32 {
  // Placeholder observable output; the CMake-example version will print
  // the marker line in EXPECT-STDOUT via a linked print routine.
  Core.Print(1);
  return 0;
}
