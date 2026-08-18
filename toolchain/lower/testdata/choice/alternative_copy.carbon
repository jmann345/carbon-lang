// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/alternative_copy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/alternative_copy.carbon

// The synthesized choice `Core.Copy` witness's lowering, both reprs (W-075,
// fork/w075/plan.md §2/§3 P-3): a payload-free choice has a copy value/init
// repr, so its `Copy.Op` lowers by value (`PrimitiveCopy` with no return
// slot); a payload-carrying choice is pointer-rep/in-place
// (sem_ir/type_info.cpp: `ValueRepr::Pointer` -> `InitRepr::InPlace`), so
// its `Copy.Op` call carries a return slot as the trailing arg and the
// handle_call.cpp arm memcpys through `CopyValue` — a wrong arm cannot
// hide (plan §5 R-4: the by-value fallback would visibly miscompile the
// slot shape). Copies of CONSTANT alternatives fold in eval
// (`PrimitiveCopy` constant-forwards), so runtime bindings carry the
// runtime-call pins.

// --- copy_rep.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// A runtime copy: by-value `PrimitiveCopy`, no slot.
fn Passthrough(f: Flag) -> Flag { return f; }

// A constant copy: folds in eval, lowered as the constant.
fn MakeOn() -> Flag { return Flag.On; }

// --- pointer_rep.carbon
library "[[@TEST_NAME]]";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// A runtime copy into the return slot: the trailing arg carries the slot,
// and the lowering is a memcpy of the object repr.
fn Passthrough(p: Pair(i64)) -> Pair(i64) { return p; }

// The W-075 minting shape: the payload-free alternative constant of a
// payload-carrying choice, returned by value through the slot.
fn MakeNeither() -> Pair(i64) { return Pair(i64).Neither; }

// var initialization from a runtime binding (slot = the var's storage), then
// re-assignment from the constant alternative.
fn RoundTrip(p: Pair(i64)) -> Pair(i64) {
  var q: Pair(i64) = p;
  q = Pair(i64).Neither;
  return q;
}
