// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/parts/uint.carbon

// --- min_prelude/parts/try.carbon

package Core library "prelude/parts/try";

// The choice's discriminant type and construction need the integer types.
import library "prelude/parts/uint";

// Mirrors core/prelude/try.carbon (library "prelude/try"): the alternative
// order fixes the discriminants Continue = 0 / Break = 1, which the postfix
// `?` desugar's discriminant test depends on.
choice ControlFlow(C: type, B: type) {
  Continue(value: C),
  Break(value: B)
}

interface Try {
  let ContinueType: type;
  let BreakType: type;
  fn Branch(self) -> ControlFlow(ContinueType, BreakType);
  fn FromBreak(b: BreakType) -> Self;
}
