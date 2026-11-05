// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — synthesizing Carbon overloads for imported C++ types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   -72
//   1
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P14 code block of
// docs/design/interoperability/README.md, section "The operator
// interoperability model", byte for byte (fork/designdocs/check_samples.py,
// rulebook R27). Expected output derived by hand in fork/designdocs/plan.md
// section 4 (R16(d)). Runs on this fork's toolchain and on the upstream
// nightly. A PASS shows that the documented sample runs as documented; the
// design-docs bullet itself is arbitrated by document review.

import Core library "io";

import Cpp inline '''c++
struct Money {
  int cents;
  static Money Make(int c) { return Money{c}; }
  Money operator-() const { return Money{-cents}; }
  friend Money operator+(Money a, Money b) { return Money{a.cents + b.cents}; }
  friend Money& operator+=(Money& a, Money b) {
    a.cents += b.cents;
    return a;
  }
  friend bool operator==(Money a, Money b) { return a.cents == b.cents; }
  friend bool operator<(Money a, Money b) { return a.cents < b.cents; }
};
''';

fn Run() -> i32 {
  var a: Cpp.Money = Cpp.Money.Make(30);
  let b: Cpp.Money = Cpp.Money.Make(12);
  // Carbon operator syntax calls the C++ operators that C++ overload
  // resolution selects.
  var c: Cpp.Money = a + b;
  Core.Print(c.cents);
  c += a;
  Core.Print((-c).cents);
  if (a == Cpp.Money.Make(30) and b < a) {
    Core.Print(1);
  }
  return 0;
}
