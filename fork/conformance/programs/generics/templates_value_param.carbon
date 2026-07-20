// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   9
//   10
//   20
//
// Working slice of integrated templates: non-type template parameters
// (`template N: i32`, `template B: bool`) declared in the runtime parameter
// list, substituted as constants during monomorphization and used in the
// function body (returned directly; branched on). Parameter-list `template`
// syntax verbatim from toolchain/check/testdata/function/generic/
// template_param.carbon (`fn F(unused template T: type)`); each distinct
// template argument produces its own runnable specific.

import Core library "io";

fn Repeat(template N: i32) -> i32 {
  return N;
}

fn Pick(template B: bool, x: i32, y: i32) -> i32 {
  if (B) {
    return x;
  }
  return y;
}

fn Run() -> i32 {
  Core.Print(Repeat(9));
  Core.Print(Pick(true, 10, 20));
  Core.Print(Pick(false, 10, 20));
  return 0;
}
