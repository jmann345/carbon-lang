// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "twice.h"

#include <iostream>

int Twice(int n) { return 2 * n; }

void PrintMarker() {
  std::cout << "built by a drop-in Clang build-system example\n";
}
