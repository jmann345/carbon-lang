// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/unit_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/unit_payload.carbon

// The zero-sized empty tuple `()` as a choice payload element (W-070 option
// (a), fork/eh/plan.md D-EH-2): `IsInSliceChoicePayloadType` admits it, on
// the definition path (`U` below) and on the per-specific evaluation path
// (`Core.ControlFlow(i32, ())`, the unit break carrier `Optional`'s `Try`
// impl needs — decision D9 of docs/design/error_handling.md). The second
// subfile is the positive flip of fail_question_preflight.carbon's former
// unit-break-type rejection pin. A `((),)` payload tuple has size 0, so neither
// choice's layout gains any payload bytes from it.

// --- unit_payload.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

//@dump-sem-ir-begin
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
//@dump-sem-ir-end

// --- control_flow_unit.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

//@dump-sem-ir-begin
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
//@dump-sem-ir-end
