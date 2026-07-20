// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Packages
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// Cross-package import: this Main//default file imports the Core package's
// "io" library (`import <Package> library "<lib>"`, the shape in
// toolchain/check/testdata/packages/cross_package_import.carbon and every
// examples/advent2024/ file). Core's implicitly imported prelude library and
// the explicit "io" import merge into the one package namespace `Core`:
// `Core.Int` resolves from Core//prelude while `Core.Print` resolves from
// Core//io, both via package-qualified member access.

import Core library "io";

fn Double(n: Core.Int(32)) -> Core.Int(32) { return n * 2; }

fn Run() -> i32 {
  Core.Print(Double(21));
  return 0;
}
