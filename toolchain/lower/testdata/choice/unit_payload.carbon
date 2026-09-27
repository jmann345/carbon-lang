// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/unit_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/unit_payload.carbon
// CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:71:42: error: cannot access member of interface `Destroy` in type `T` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:       return ControlFlow(T, ()).Continue(self.Get());
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:71:42: error: cannot access member of interface `Destroy` in type `T` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:       return ControlFlow(T, ()).Continue(self.Get());
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR:

// The zero-sized `()` payload, lowered (W-070 option (a), fork/eh/plan.md
// D-EH-2, risk R-3): a `((),)` payload tuple is a one-element tuple of an
// empty aggregate, so constructing `A(())` / `Break(())` stores a `{ {} }`
// into the payload region at offset 0 — a legal zero-size store — and the
// region's size is the max over the OTHER payloads: `U` lays out with a
// 4-byte region for `B(i32)`, and `Core.ControlFlow(i32, ())` as
// `<{ <{ i1, [3 x i8] }>, [4 x i8] }>` (the discriminant sub-struct padded
// to the `i32` payload's alignment). The falsifier for D-EH-2's break
// condition is a lowering crash or a non-zero-size region for the `()` arm.

// --- unit_payload.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

choice U {
  A(x: ()),
  B(y: i32)
}

fn MakeA() -> U { return U.A(()); }
fn MakeB(n: i32) -> U { return U.B(n); }

fn Classify(u: U) -> i32 {
  match (u) {
    case .A(x: ()) => {
      Sink(x);
      return 0;
    }
    case .B(y: i32) => { return y; }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -1;
}

// --- control_flow_unit.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

fn MakeBreak() -> Core.ControlFlow(i32, ()) {
  return Core.ControlFlow(i32, ()).Break(());
}

fn MakeContinue(n: i32) -> Core.ControlFlow(i32, ()) {
  return Core.ControlFlow(i32, ()).Continue(n);
}

fn Classify(c: Core.ControlFlow(i32, ())) -> i32 {
  match (c) {
    case .Continue(v: i32) => { return v; }
    case .Break(b: ()) => {
      Sink(b);
      return -1;
    }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -2;
}
