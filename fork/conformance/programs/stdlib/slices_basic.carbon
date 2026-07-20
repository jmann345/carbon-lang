// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Slices
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   3
// SKIP: MISSING — grep for Slice in core/ returns nothing: no slice type exists anywhere in the Core package (and heap allocation is likewise absent), so a non-owning contiguous view over an array cannot be expressed today. Un-SKIP (and uncomment the body) when W9 delivers a Core slice type with construction-from-array, indexing, and size.
//
// Write-tests-first stub. Intended future test: build a Core slice as a
// non-owning view over the middle of a stack array (array shape from
// stdlib/tuples_arrays_structs.carbon), then read length and elements
// through the view — proving slices alias the underlying storage rather
// than copying. The `Core.Slice(i32)` API below is a strawman pending the
// approved design.

import Core library "io";

fn Run() -> i32 {
  // Intended body once the feature lands (strawman API):
  //   var a: array(i32, 4) = (1, 2, 3, 4);
  //   let s: Core.Slice(i32) = Core.Slice(i32).Make(&a, 1, 3);  // view of a[1..3]
  //   Core.Print(s.Size() as i32);       // 2
  //   Core.Print(s[1]);                  // 3 — reads through to `a`
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before a
  // Core slice type exists.
  return 1;
}
