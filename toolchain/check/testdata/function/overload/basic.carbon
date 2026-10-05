// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/basic.carbon

// Same-file `overload fn` closed sets (fork decision F-009; fork/overload/plan.md
// OV-1). Name lookup of an overloaded name binds the set value, never a member;
// a call resolves to the first member, in declaration order, whose parameters
// accept the arguments through implicit conversions, and then compiles as an
// ordinary call to that member.

// --- two_members.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Describe(unused n: i32) -> i32 { return 1; }
overload fn Describe(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return Describe(7) + Describe(true); }
//@dump-sem-ir-end

// --- first_match_order.carbon

library "[[@TEST_NAME]]";

// Declaration order decides: `i32` widens implicitly to `i64`, so the first
// member is selected for an `i32` argument even though the second is an exact
// match. There is no best-match ranking.
//@dump-sem-ir-begin
overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

fn Use(n: i32) -> i32 { return Pick(n); }
//@dump-sem-ir-end

// --- arity_dispatch.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Sum(a: i32) -> i32 { return a; }
overload fn Sum(a: i32, b: i32) -> i32 { return a + b; }

fn Use() -> i32 { return Sum(1) + Sum(2, 3); }
//@dump-sem-ir-end

// --- method_set.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
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
//@dump-sem-ir-end

// --- alias_of_set.carbon

library "[[@TEST_NAME]]";

// An alias names the whole set (D-OV-10).
//@dump-sem-ir-begin
overload fn Twice(x: i32) -> i32 { return x * 2; }
overload fn Twice(b: bool) -> i32 { if (b) { return 2; } return 0; }

alias Double = Twice;

fn Use() -> i32 { return Double(1) + Double(false); }
//@dump-sem-ir-end

// --- fail_later_member_not_visible.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }

// File-scope bodies are checked in order (information accumulation), so the
// set has one member here and `F(true)` has no candidate.
fn G() -> i32 {
  // CHECK:STDERR: fail_later_member_not_visible.carbon:[[@LINE+7]]:10: error: no member of overload set `F` accepts this call [OverloadNoMatch]
  // CHECK:STDERR:   return F(true);
  // CHECK:STDERR:          ^~~~~~~
  // CHECK:STDERR: fail_later_member_not_visible.carbon:[[@LINE-8]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
  // CHECK:STDERR: overload fn F(unused x: i32) -> i32 { return 1; }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return F(true);
}

overload fn F(unused b: bool) -> i32 { return 2; }

// --- class_defers.carbon

library "[[@TEST_NAME]]";

// Class member function bodies are deferred to the end of the class, so the
// whole set is visible from a sibling method even when declared later.
//@dump-sem-ir-begin
class Cd {
  fn Use(unused self) -> i32 { return F(true); }
  overload fn F(unused x: i32) -> i32 { return 1; }
  overload fn F(unused b: bool) -> i32 { return 2; }
}
//@dump-sem-ir-end

// --- forward_decl_and_def.carbon

library "[[@TEST_NAME]]";

// Each definition merges into its type-equal member (D-OV-3).
//@dump-sem-ir-begin
overload fn H(x: i32) -> i32;
overload fn H(b: bool) -> i32;

overload fn H(x: i32) -> i32 { return x; }
overload fn H(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return H(1) + H(true); }
//@dump-sem-ir-end

// --- local_set.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Outer() -> i32 {
  overload fn L(unused x: i32) -> i32 { return 1; }
  overload fn L(unused b: bool) -> i32 { return 2; }
  return L(true);
}
//@dump-sem-ir-end

// --- raw_identifier.carbon

library "[[@TEST_NAME]]";

// `overload` is a keyword; the raw identifier spelling remains available.
//@dump-sem-ir-begin
fn Use() -> i32 {
  var r#overload: i32 = 1;
  return r#overload;
}
//@dump-sem-ir-end

// --- single_member.carbon

library "[[@TEST_NAME]]";

// A single marked declaration is a legal one-member set.
//@dump-sem-ir-begin
overload fn Solo(x: i32) -> i32 { return x; }

fn Use() -> i32 { return Solo(3); }
//@dump-sem-ir-end

// --- discard_probe_constants.carbon

library "[[@TEST_NAME]]";

// Probing the first member fails on an `ImplicitAs` impl lookup and leaves no
// `converted`/`call` instruction behind; the second member matches.
//@dump-sem-ir-begin
overload fn Q(unused x: i32) -> i32 { return 1; }
overload fn Q(unused t: (i32, i32)) -> i32 { return 2; }

fn Use() -> i32 { return Q((1, 2)); }
//@dump-sem-ir-end

// --- init_arg.carbon

library "[[@TEST_NAME]]";

// An initializing argument is probed against the rejected first member without
// leaking a temporary or its cleanup into the enclosing block: exactly one
// temporary and one cleanup for the argument, from the committed call.
//@dump-sem-ir-begin
class C {
  var n: i32;
}

fn G() -> C { return {.n = 1}; }

overload fn F(unused b: bool) -> i32 { return 1; }
overload fn F(c: C) -> i32 { return c.n; }

fn Use() -> i32 { return F(G()); }
//@dump-sem-ir-end

// --- destroy_arg.carbon

library "[[@TEST_NAME]]";

// As `init_arg`, with a user-provided destructor: one destroy call per
// statement.
//@dump-sem-ir-begin
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
//@dump-sem-ir-end

// --- literal_range.carbon

library "[[@TEST_NAME]]";

// An integer literal that does not fit a member's integer parameter rejects
// that member silently (no `IntTooLargeForType` / `NegativeIntInUnsignedType`
// diagnostic); the next member is selected.
//@dump-sem-ir-begin
overload fn N(unused x: i8) -> i32 { return 1; }
overload fn N(unused x: i32) -> i32 { return 2; }

overload fn U(unused x: u8) -> i32 { return 1; }
overload fn U(unused x: i32) -> i32 { return 2; }

fn Use() -> i32 { return N(300) + U(-1); }
//@dump-sem-ir-end

// --- class_scope_call.carbon

library "[[@TEST_NAME]]";

// A non-method set called through the class scope and unqualified: no bound
// method is formed.
//@dump-sem-ir-begin
class K {
  overload fn S(unused x: i32) -> i32 { return 1; }
  overload fn S(unused b: bool) -> i32 { return 2; }
  fn Use() -> i32 { return K.S(true) + S(1); }
}
//@dump-sem-ir-end

// --- explicit_receiver.carbon

library "[[@TEST_NAME]]";

// A method set named through the class scope or an alias with the receiver
// passed explicitly: argument 0 binds to the by-value `self` pattern.
//@dump-sem-ir-begin
class K {
  overload fn M(unused self, unused x: i32) -> i32 { return 1; }
  overload fn M(unused self, unused b: bool) -> i32 { return 2; }
}

alias A = K.M;

fn Use(k: K) -> i32 { return K.M(k, 1) + A(k, true); }
//@dump-sem-ir-end

// --- union_scope_set.carbon

library "[[@TEST_NAME]]";

// Member functions of unions overload under the same rules as classes.
//@dump-sem-ir-begin
union U {
  var a: i32;
  var b: i64;
  overload fn Set(ref self, x: i32) { self.a = x; }
  overload fn Set(ref self, x: i64) { self.b = x; }
}

fn Use() {
  var u: U = {.a = 1};
  u.Set(2);
  u.Set(3 as i64);
}
//@dump-sem-ir-end

// --- call_from_generic_body.carbon

library "[[@TEST_NAME]]";

// A call from a checked-generic body resolves once, at the definition, against
// the symbolic argument type: `T`'s constraint guarantees the conversion to
// `i32`, so the first member is selected for every specific.
//@dump-sem-ir-begin
overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P(unused b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

fn Use() -> i32 { return Gen(7 as i16); }
//@dump-sem-ir-end

// --- marked_typo_undefined_member.carbon

library "[[@TEST_NAME]]";

// A marked signature typo legally declares a two-member set whose first
// member is never defined. Today an api-declared function without a
// definition is accepted and fails at link time; OV-2 extends the impl-file
// missing-definition check to api-declared set members (fork/overload/plan.md
// §1.B.7).
//@dump-sem-ir-begin
overload fn G(x: i64) -> i64;
overload fn G(unused x: u64) -> i64 { return 1; }

fn Use() -> i64 { return G(1 as u64); }
//@dump-sem-ir-end
