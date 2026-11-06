// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Core library "io";
import Cpp library "twice.h";

fn Run() -> i32 {
  Cpp.PrintMarker();
  Core.Print(Cpp.Twice(21));
  return 0;
}
