// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: installs on Windows, macOS, and Linux and builds working programs
// EXPECT-EXIT: 42
//
// The smallest possible arbiter: a `Run` entry point whose i32 return value
// becomes the process exit code. Modeled on
// toolchain/check/testdata/main_run/return_i32.carbon; `Run` in Main//default
// lowers to `main` (toolchain/lower/testdata/namespace/namespace_run.carbon).

fn Run() -> i32 {
  return 42;
}
