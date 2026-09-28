// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/basic.carbon

// Every member of an `overload fn` set lowers to its own definition, mangled
// with its set-relative index (`:overload<N>`, D-OV-5); a resolved call names
// the selected member's symbol directly.

// --- two_members.carbon

library "[[@TEST_NAME]]";

overload fn Describe(unused n: i32) -> i32 { return 1; }
overload fn Describe(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return Describe(7) + Describe(true); }

// --- first_match_order.carbon

library "[[@TEST_NAME]]";

overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

fn Use(n: i32) -> i32 { return Pick(n); }

// --- arity_dispatch.carbon

library "[[@TEST_NAME]]";

overload fn Sum(a: i32) -> i32 { return a; }
overload fn Sum(a: i32, b: i32) -> i32 { return a + b; }

fn Use() -> i32 { return Sum(1) + Sum(2, 3); }

// --- method_set.carbon

library "[[@TEST_NAME]]";

class Acc {
  var total: i32;
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
}

fn Use() {
  var a: Acc = {.total = 0};
  a.Add(1);
  a.Add(true);
}

// --- alias_of_set.carbon

library "[[@TEST_NAME]]";

overload fn Twice(x: i32) -> i32 { return x * 2; }
overload fn Twice(b: bool) -> i32 { if (b) { return 2; } return 0; }

alias Double = Twice;

fn Use() -> i32 { return Double(1) + Double(false); }

// --- local_set.carbon

library "[[@TEST_NAME]]";

fn Outer() -> i32 {
  overload fn L(unused x: i32) -> i32 { return 1; }
  overload fn L(unused b: bool) -> i32 { return 2; }
  return L(true);
}

// --- init_arg.carbon

library "[[@TEST_NAME]]";

// One temporary for the argument, one call to `G` storing into it, one call
// to the selected member, and one cleanup: the rejected probe of the first
// member leaks nothing.
class C {
  var n: i32;
}

fn G() -> C { return {.n = 1}; }

overload fn F(unused b: bool) -> i32 { return 1; }
overload fn F(c: C) -> i32 { return c.n; }

fn Use() -> i32 { return F(G()); }

// --- destroy_arg.carbon

library "[[@TEST_NAME]]";

class D {
  var n: i32;
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn MakeD() -> D { return {.n = 1}; }

overload fn F(unused b: bool) -> i32 { return 1; }
overload fn F(d: D) -> i32 { return d.n; }

fn Use() -> i32 { return F(MakeD()); }

// --- literal_range.carbon

library "[[@TEST_NAME]]";

overload fn N(unused x: i8) -> i32 { return 1; }
overload fn N(unused x: i32) -> i32 { return 2; }

overload fn U(unused x: u8) -> i32 { return 1; }
overload fn U(unused x: i32) -> i32 { return 2; }

fn Use() -> i32 { return N(300) + U(-1); }

// --- call_from_generic_body.carbon

library "[[@TEST_NAME]]";

overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P(unused b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

fn Use() -> i32 { return Gen(7 as i16); }
