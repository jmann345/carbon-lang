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

// The zero-sized `()` payload, lowered (W-070 option (a), fork/eh/plan.md
// D-EH-2, risk R-3). Two construction regimes are pinned, and they differ:
//
// - `U.A(())` on the NON-GENERIC `U`: the payload tuple `((),)` has exactly
//   one value, so inside `@U.A` the parameter's conversion folds to a
//   constant and the constructor's `class_init` folds to the `StructValue`
//   `%U.val = struct_value (%int_0, %tuple)` whose payload element carries
//   the TUPLE type `((),)` (LLVM `{ {} }`), not the region type `[4 x i8]`
//   (check/testdata/choice/unit_payload.carbon:123). Lowering emits it as
//   the template `@U.val = internal constant <{ <{ i1, [3 x i8] }>,
//   [4 x i8] }>` with a zero-filled region (constant.cpp `PadToType`'s
//   zero-sized-in-byte-region arm) and `@U.A` memcpys the template into the
//   return slot -- the `alternative_copy.carbon` `@Flag.val` shape. R-3's
//   falsifier FIRED on the first fill (run 36301651448: `PadToType`'s
//   CHECK, `{ {} }` against `[4 x i8]`); this file is the regression pin.
// - `Core.ControlFlow(i32, ()).Break(())` on the GENERIC prelude choice: the
//   payload is symbolic in the constructor, so it takes handle_choice.cpp's
//   cover-then-update path and the `((),)` reaches the region through a
//   runtime zero-size `store { {} }` at offset 0 -- no folded constant. The
//   region's size is the max over the OTHER payloads: `<{ <{ i1, [3 x i8] }>,
//   [4 x i8] }>` (discriminant sub-struct padded to the `i32` payload's
//   alignment).
//
// The `multi_unit_payload.carbon` subfile pins the second folding shape,
// `((), ())`: a two-element all-zero-sized payload tuple (LLVM `{ {}, {} }`)
// folds the same way and takes the same arm. `U.B(n)` / `V.D(n)` pin that a
// non-zero-sized payload never folds (it depends on the parameter) and is
// unaffected. The D-EH-2 break condition's falsifier remains a lowering
// crash or a non-zero-size region for the `()` arm.

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

// --- multi_unit_payload.carbon
library "[[@TEST_NAME]]";

fn Sink(unused u: ()) {}

choice V {
  C(x: (), y: ()),
  D(z: i32)
}

fn MakeC() -> V { return V.C((), ()); }
fn MakeD(n: i32) -> V { return V.D(n); }

fn Classify(v: V) -> i32 {
  match (v) {
    case .C(x: (), y: ()) => {
      Sink(x);
      Sink(y);
      return 0;
    }
    case .D(z: i32) => { return z; }
  }
  // Unreachable trailing return: reachability doesn't consult match
  // exhaustiveness.
  return -1;
}

