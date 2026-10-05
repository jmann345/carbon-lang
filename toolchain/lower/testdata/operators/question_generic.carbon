// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/question_generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/question_generic.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// The instantiated-generic `?` golden (fork/b2/plan.md §3, the B2a exit
// criterion as revised; risk R-1's falsifiers): a generic `?` body checked
// under §2.2's symbolic-choice destroy answer, monomorphized at concrete
// arguments. The specific's CFG must carry the concrete discriminant test,
// payload access, `FromBreak` call and early `ret` — and the SAME
// no-op-body destroy-call shape the concrete baseline pins
// (lower/testdata/operators/question.carbon `_CBasic.Main`): calls to empty
// `weak_odr` `_COp…core.Destroy.Core` definitions on BOTH exclusive paths.
// Falsification is a destroy call whose definition body is NON-EMPTY, a
// USER `Destroy` impl invoked on the propagation path, or destroy calls
// ABSENT where the concrete baseline has them. `adapter_payload.carbon` is
// the S1 admitted-exception probe: a payload adapter carrying a user
// `Core.Destroy` impl — the concrete re-derivation answers `NonTrivial`
// for the choice (which is why §2.2's symbolic answer is
// `NonTrivial`-deferred, never `Trivial`), and the choice's synthesized
// destroy op stays a placeholder no-op that runs no member destructor, so
// the user impl is never invoked on the propagation path. Since SL-1
// (fork/slices/plan.md R-12, amended 2026-10-05) the adapter's OWN destroy
// witness is its declared impl, not a synthesized one: no
// `_COp…core.Destroy.Core` definition for `Tag` is emitted any more.

// --- generic.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction). The explicit generic type
// param + self-recursion is the arbiter-verified
// function/generic/deduce.carbon `ExplicitGenericParam` shape.
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, W-073 dated
    // amendment): reachability doesn't consult match exhaustiveness; no
    // generic `ControlFlow(T, E)` value is conjurable, and through this
    // NON-final impl the interface-recursive call does not type-collapse
    // (upstream specialization soundness keeps its projections unreduced;
    // under `final` it does — question_final.carbon), so use the helper.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// The restored W-071 discharge body (check golden
// check/testdata/operators/question.carbon, generic split): `?` on a
// facet-bound operand, carrier `Core.ControlFlow(R.ContinueType, i32)` —
// symbolic at check time, concrete in the instantiation below.
fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}

// The concrete instantiation that lowers the specific: `R` deduced as
// `MyResult(i32, i32)` (param-to-param forwarding, the
// match/choice_generic_scrutinee.carbon `Classify`/`F` shape).
fn Call(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  return PropagateOnly(r);
}

// --- adapter_payload.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction).
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, dated
    // correction).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// The S1 admitted-exception shape: an SF-6-admissible payload adapter (over
// `i32`) that carries a USER `Core.Destroy` impl. The payload allowlist does
// not query destroy witnesses, so this passes SF-6; the concrete destroy
// re-derivation of `MyResult(Tag, i32)` finds the user witness for `Tag`
// (through impl lookup — the destroy custom witness yields to a declared
// impl, custom_witness.cpp `CanDestroyClass`) and answers `NonTrivial`.
// While member destruction in destroy-op synthesis is a placeholder, the
// lowered destroy calls on the propagation path (on `MyResult`/`ControlFlow`
// temporaries, never on a `Tag` object) remain calls to EMPTY no-op bodies
// that never invoke `Tag.as.Destroy.impl.Op` — §2.2's revisit note carries
// the future obligation.
class Tag {
  adapt i32;
}

// The upstream user-impl shape (lower/testdata/var/destroy_control_flow.carbon
// `impl as Core.Destroy { fn Op(self); }`), with a defined no-op body so the
// golden can prove it is never called on the propagation path.
impl Tag as Core.Destroy {
  // CHECK:STDERR: adapter_payload.carbon:[[@LINE+4]]:9: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Op(self) {}
  // CHECK:STDERR:         ^~~~
  // CHECK:STDERR:
  fn Op(self) {}
}

fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}

fn CallAdapter(r: MyResult(Tag, i32)) -> MyResult(Tag, i32) {
  return PropagateOnly(r);
}

