// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: C++ interop — exporting Carbon functions/methods to C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   14
//   42
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P18 code block of
// docs/design/interoperability/README.md, section "Using Carbon from C++", byte
// for byte (fork/designdocs/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this
// fork's toolchain and on the upstream nightly. A PASS shows that the
// documented sample runs as documented; the design-docs bullet itself is
// arbitrated by document review.

import Core library "io";
import Cpp;

class Counter {
  var n: i32;
  fn Make(start: i32) -> Counter { return {.n = start}; }
  fn Get(self) -> i32 { return self.n; }
  fn Add(ref self, k: i32) { self.n += k; }
}

fn Twice(n: i32) -> i32 { return n * 2; }

interface Doubler {
  fn Double(self) -> Self;
}

class Meters {
  var n: i32;
  fn Make(v: i32) -> Meters { return {.n = v}; }
  fn Value(self) -> i32 { return self.n; }
  impl as Doubler {
    fn Double(self) -> Self { return {.n = self.n * 2}; }
  }
}

// A checked generic is exported as a C++ function template.
fn DoubleIt[T: Doubler](x: T) -> T { return x.Double(); }

// C++ code names Carbon declarations through the `Carbon` namespace.
inline Cpp '''c++
inline int UseCarbon(int start) {
  Carbon::Counter c = Carbon::Counter::Make(start);
  c.Add(3);
  return Carbon::Twice(c.Get());
}

inline int UseGeneric() {
  return Carbon::DoubleIt(Carbon::Meters::Make(21)).Value();
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseCarbon(4));
  Core.Print(Cpp.UseGeneric());
  return 0;
}
