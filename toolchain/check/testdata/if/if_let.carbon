// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/if/if_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/if/if_let.carbon

// Pattern conditions (W-012, fork/design-sprint/if-let.md Option A): the
// condition of an `if` is a refutable pattern binding, checked on the
// `match` case-arm machinery (refutable_binding.h). The pattern is checked
// before its initializer, so a root alternative pattern resolves against the
// scrutinee's choice type at the test; the test pass emits the arm's
// condition in the enclosing block and branches `if.then`/`if.else`, and
// the bind pass initializes the bindings in the then block, whose scope
// they belong to.

// --- alternative_payload.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(opt: OptInt) -> i32 {
  if (let .Some(n: i32) = opt) {
    return n;
  } else {
    return 0;
  }
}
//@dump-sem-ir-end

// --- alternative_bare.carbon
library "[[@TEST_NAME]]";

// A bare `.Name`: the discriminant test alone, and no bind-pass insts (the
// synthesized payload root is empty).
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(opt: OptInt) -> i32 {
  if (let .None = opt) {
    return 0;
  }
  return 1;
}
//@dump-sem-ir-end

// --- payload_literal.carbon
library "[[@TEST_NAME]]";

// The payload comparison is in a block dominated by the discriminant test.
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(opt: OptInt) -> i32 {
  if (let .Some(42) = opt) {
    return 1;
  }
  return 0;
}
//@dump-sem-ir-end

// --- tuple_root.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(pair: (i32, i32)) -> i32 {
  if (let (0, n: i32) = pair) {
    return n;
  }
  return -1;
}
//@dump-sem-ir-end

// --- var_alternative.carbon
library "[[@TEST_NAME]]";

// The var-alternative lane (decision R29a): the discriminant test, then one
// payload-tuple-typed on-demand `VarStorage` in the then block, initialized
// from the payload field ref and bound elementwise.
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(opt: OptInt) -> i32 {
  if (var .Some(n: i32) = opt) {
    n = n + 1;
    return n;
  }
  return 0;
}
//@dump-sem-ir-end

// --- var_tuple_root.carbon
library "[[@TEST_NAME]]";

// A `var` root over an all-binding tuple: the irrefutable-`var` lane (one
// tuple-typed on-demand storage, bound elementwise). The pattern cannot
// fail, so the form warns.
//@dump-sem-ir-begin
fn F(pair: (i32, i32)) -> i32 {
  if (var (m: i32, n: i32) = pair) {
    m = m + n;
    return m;
  }
  return -1;
}
//@dump-sem-ir-end

// --- bool_scrutinee.carbon
library "[[@TEST_NAME]]";

// A bool expression-pattern root (the W-076 lane).
//@dump-sem-ir-begin
fn F(b: bool) -> i32 {
  if (let true = b) {
    return 1;
  }
  return 0;
}
//@dump-sem-ir-end

// --- nested_payload_tuple.carbon
library "[[@TEST_NAME]]";

// A payload tuple walk with an expression element under the discriminant
// test.
choice Q {
  Some(p: (i32, i32)),
  None
}

//@dump-sem-ir-begin
fn F(q: Q) -> i32 {
  if (let .Some((1, n: i32)) = q) {
    return n;
  }
  return -1;
}
//@dump-sem-ir-end

// --- ref_binding.carbon
library "[[@TEST_NAME]]";

// A `ref` payload binding on a `var` scrutinee binds the payload field
// itself.
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F() -> i32 {
  var v: OptInt = OptInt.Some(1);
  if (let .Some(ref r: i32) = v) {
    r = r + 1;
    return r;
  }
  return 0;
}
//@dump-sem-ir-end

// --- else_if_chain.carbon
library "[[@TEST_NAME]]";

// Two pattern conditions chained: the first if-let's scope is popped before
// the chained `if`, whose own if-let scope nests in the else arm.
//@dump-sem-ir-begin
fn F(pair: (i32, i32)) -> i32 {
  if (let (0, n: i32) = pair) {
    return n;
  } else if (let (m: i32, 0) = pair) {
    return m;
  } else {
    return -1;
  }
}
//@dump-sem-ir-end

// --- question_in_initializer.carbon
library "[[@TEST_NAME]]";

// `?` is legal in the initializer: the pattern's region is closed before
// the initializer is checked, so the initializer runs at region depth 1
// (fork/w012/plan.md §1.7).
choice OptInt {
  Some(x: i32),
  None
}

class Tok {
  adapt i32;
}

impl Tok as Core.Copy {
  fn Op(self) -> Self = "primitive_copy";
}

impl Tok as Core.Try where .ContinueType = i32 and .BreakType = i32 {
  fn Branch(self) -> Core.ControlFlow(i32, i32) {
    if ((self as i32) < 0) {
      return Core.ControlFlow(i32, i32).Break(self as i32);
    }
    return Core.ControlFlow(i32, i32).Continue(self as i32);
  }
  fn FromBreak(b: i32) -> Self { return b as Tok; }
}

fn Wrap(n: i32) -> OptInt { return OptInt.Some(n); }

//@dump-sem-ir-begin
fn G(t: Tok) -> Tok {
  if (let .Some(n: i32) = Wrap(t?)) {
    return n as Tok;
  }
  return 0 as Tok;
}
//@dump-sem-ir-end

// --- struct_root.carbon
library "[[@TEST_NAME]]";

// A struct root (the W-077 lane), admitted by way of the shared
// `MatchCaseArm` context.
//@dump-sem-ir-begin
fn F(s: {.a: i32, .b: i32}) -> i32 {
  if (let {.a = 1, b: i32} = s) {
    return b;
  }
  return -1;
}
//@dump-sem-ir-end
