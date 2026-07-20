// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   6
// SKIP: MISSING — no Carbon slice type exists (grep for Slice in core/ returns nothing) and there is no std::span/vector view mapping: only ordinary API import of containers works, so a Carbon array cannot be passed transparently as std::span and an owning std::vector cannot be viewed as a Carbon slice. Un-SKIP (and uncomment the body) when the Core slice type (W9) and its contiguous-container interop mapping land.
//
// Write-tests-first stub. Intended future test, both directions of the
// mapping: (1) pass a Carbon array to a C++ function taking
// std::span<const int> without copying; (2) owning->view — obtain an
// owning Cpp.std.vector from C++ and view it as a Carbon slice, reading
// an element through the view. C++ block shape from
// interop/cpp_operator_import_arithmetic.carbon; the Carbon-side slice
// spelling is a strawman pending the approved design.

import Core library "io";
// import Cpp inline '''c++
// #include <numeric>
// #include <span>
// #include <vector>
//
// inline int SumSpan(std::span<const int> s) {
//   return std::accumulate(s.begin(), s.end(), 0);
// }
//
// inline std::vector<int> MakeVector() { return {2, 4, 6}; }
// ''';

fn Run() -> i32 {
  // Intended body once the feature lands (strawman slice spelling):
  //   var a: array(i32, 4) = (1, 2, 3, 4);
  //   Core.Print(Cpp.SumSpan(a));                 // Carbon array -> std::span
  //   var v: Cpp.std.vector(i32) = Cpp.MakeVector();
  //   let view: Core.Slice(i32) = v.AsSlice();    // owning -> non-owning view
  //   Core.Print(view[2]);                        // 6
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before the
  // contiguous-container mapping exists.
  return 1;
}
