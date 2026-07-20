// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// The export direction of the bullet: a Carbon class used as a type from
// C++. A mid-file `inline Cpp '''...'''` declaration (form verbatim from
// check/testdata/interop/cpp/class/export/{class,field,method}.carbon:
// `import Cpp;` + declarations + `inline Cpp` block) lets C++ code
// default-construct `Carbon::Tally`, write its i32 field, call its
// `ref self` and by-value-`self` methods (dispatched through the exported
// weak_odr thunks shown in lower/testdata/interop/cpp/class/export/
// method.carbon), and return the result to Carbon, which prints it — so
// the Carbon->C++->Carbon round trip is checked at runtime.

import Core library "io";
import Cpp;

class Tally {
  var count: i32;

  fn Bump(ref self) { self.count = self.count + 1; }
  fn Total(self) -> i32 { return self.count; }
}

inline Cpp '''
int UseTally() {
  Carbon::Tally t;
  t.count = 40;
  t.Bump();
  t.Bump();
  return t.Total();
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseTally());
  return 0;
}
