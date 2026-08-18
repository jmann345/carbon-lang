// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/alternative_copy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/alternative_copy.carbon

// Choice copies through the synthesized `Core.Copy` witness (W-075,
// fork/w075/plan.md §2/§3): value-position consumption of a choice by an
// initializing destination — return position, `var` initialization,
// assignment — value-copies by way of `Copy.Op`, which for a choice self is
// the synthesized primitive-copy builtin (custom_witness.cpp
// `LookupChoiceCopyWitness`). These are the P-1 flips of the shapes that
// diagnosed `CopyOfUncopyableType` before the witness landed, plus the
// boundary shapes that never copied and the SF-1 shadowing pin.

// --- payload_free.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

//@dump-sem-ir-begin
// Return position: the alternative constant value-copies into the return
// through the synthesized witness's `Copy.Op` call.
fn MakeOn() -> Flag { return Flag.On; }

// var initialization from the constant, assignment from the constant, and
// return of a choice-typed runtime binding: all three previously-diagnosed
// shapes on one variable.
fn RoundTrip() -> Flag {
  var f: Flag = Flag.Off;
  f = Flag.On;
  return f;
}
//@dump-sem-ir-end

// --- doc_shape.carbon
library "[[@TEST_NAME]]";

// The design's canonical example (docs/design/sum_types.md:63-66 declaration,
// :74-75 consumption, R27 spelling-diffed): `var` initialization from the
// empty alternative's constant, then the None-to-Some transition on the same
// variable.
choice Optional(T: type) {
  Some(value: T),
  None
}

//@dump-sem-ir-begin
fn DocShape() -> Optional(i32) {
  var my_opt: Optional(i32) = Optional(i32).None;
  my_opt = Optional(i32).Some(42);
  // The transition back — assigning the `.None` constant is the same copy
  // path — and the pointer-rep binding return.
  my_opt = Optional(i32).None;
  return my_opt;
}
//@dump-sem-ir-end

// --- payload_free_of_payload_choice.carbon
library "[[@TEST_NAME]]";

// The W-075 minting shape (the W69b gate round's falsified P-5 sketch): a
// payload-carrying choice's payload-free alternative constant returned by
// value. `Pair(i64)` is pointer-rep/in-place, so the synthesized `Copy.Op`
// call carries a return slot.
choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

//@dump-sem-ir-begin
fn MakeNeither() -> Pair(i64) { return Pair(i64).Neither; }
//@dump-sem-ir-end

// --- boundary.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

fn Take(unused f: Flag) -> i32 { return 0; }

//@dump-sem-ir-begin
// Unaffected shapes (fork/w075/plan.md §0): a `let` binds the constant VALUE
// directly and a value param is a value binding — neither converts to an
// initializing destination, so no `Copy.Op` call appears in this dump.
let flag: Flag = Flag.On;

fn PassByValue() -> i32 { return Take(Flag.Off); }
//@dump-sem-ir-end

// --- generic.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

//@dump-sem-ir-begin
// Symbolic self: the copy inside the generic body defers witness building
// (`LookupChoiceCopyWitness` answers yes with `InstId::None`, the destroy
// posture); the concrete instantiation builds the primitive-copy witness at
// monomorphization — the least-exercised link (fork/w075/plan.md §5, P-1).
fn Make(generic T: type) -> Opt(T) { return Opt(T).None; }

fn UseConcrete() -> Opt(i32) { return Make(i32); }
//@dump-sem-ir-end

// --- shadowed_user_impl.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// sum_types.md:95-98 sanctions extending a choice with an out-of-line impl,
// but the custom-witness dispatch PRECEDES candidate-impl iteration
// (impl_lookup.cpp: "Only consider candidates when a custom witness didn't
// apply"), so this user `Core.Copy` impl is SHADOWED for choice selves: the
// copy below binds the synthesized primitive-copy `Copy.Op`, never `Op`
// declared here — the declared SF-1 consequence (fork/w075/plan.md review
// amendment 1), the same posture `Destroy` already has for choices. No
// diagnostic; deterministic.
impl Flag as Core.Copy {
  // `return self` is itself a value copy; it compiles without diagnostic and
  // keeps `self` used — the dump below pins which witness serves the call
  // site OUTSIDE the impl.
  fn Op(self) -> Self { return self; }
}

//@dump-sem-ir-begin
fn CopyIt(f: Flag) -> Flag { return f; }
//@dump-sem-ir-end
