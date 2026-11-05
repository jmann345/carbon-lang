// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Core library "io";
import library "widget";

fn Run() -> i32 {
  Core.PrintStr("widget package built by CMake-integrated Carbon\n");
  Core.Print(Get());
  return 0;
}
