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
//
// The arm dispatches on the CONCRETE type's init repr, never on call
// arity (fix round 2026-08-18, autoupdate run 32190561198): a call built
// against a symbolic `T: Core.Copy` carries the slot arg even when the
// lowered specific's type is by-copy, so mono_from_generic.carbon pins
// both monomorphizations of one generic body.

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

// --- mono_from_generic.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// The regression class (autoupdate run 32190561198, lower/testdata/class/
// generic.carbon's create_generic subfile): a generic body's copy call is
// built against symbolic `T: Core.Copy`, whose dependent init repr forces a
// return-slot arg — so EVERY monomorphized specific's `PrimitiveCopy` call
// has two args, and the handle_call.cpp arm must dispatch on the concrete
// init repr: by-copy specifics (Flag, i32) lower the call to the source
// VALUE (the consumer stores it), in-place specifics (Pair(i64)) memcpy
// into the slot and forward it.
fn Dup[T: Core.Copy](x: T) -> T {
  return x;
}

fn DupFlag(f: Flag) -> Flag { return Dup(f); }

fn DupInt(n: i32) -> i32 { return Dup(n); }

fn DupPair(p: Pair(i64)) -> Pair(i64) { return Dup(p); }
