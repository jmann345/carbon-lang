// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The re-exporting middle library: `export import` of the library that
// itself name-exports Rect — chaining BOTH export spellings on the route
// main.carbon uses to reach the class, the export_name_then_import shape
// of toolchain/check/testdata/packages/export_mixed.carbon.

library "reexport";

export import library "export";
