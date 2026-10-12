// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Core library "io";

fn Run() -> i32 {
  Core.PrintStr("built by CMake-integrated Carbon\n");
  return 0;
}
