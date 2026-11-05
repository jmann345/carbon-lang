// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020) un-SKIPs this
// program with its intended body: `Cpp.MaybeSeven()` returns a C++
// `std::optional<int>`, which `match` consumes as its Carbon sum type
// `Core.CppCompat.StdOptional(i32)` through the `.Some`/`.None` alternative
// patterns of docs/design/sum_types.md, so sum-type consumption spans the
// interop boundary (first-match-wins per docs/design/pattern_matching.md).
// One edit to the sketch, design-directed and not a weakening (R16(b)): the
// sketch's trailing `default` arm is removed, because the two alternative
// arms cover the closed set and a `default` after them is the dead-default
// error of W-078a (`default` arm never matches); the match is exhaustive
// without it (SF-7). The Carbon-choice half of this program's original sketch
// moved to choice_payload_roundtrip_diff.carbon at S2c.

import Core library "io";
import Cpp inline '''c++
#include <optional>
inline std::optional<int> MaybeSeven() { return 7; }
''';

fn Run() -> i32 {
  match (Cpp.MaybeSeven()) {
    case .Some(n: i32) => { Core.Print(n); }
    case .None => { return 1; }
  }
  return 0;
}
