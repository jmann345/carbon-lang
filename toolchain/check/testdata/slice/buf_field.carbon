// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/buf_field.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/buf_field.carbon

// Fork (UA-2, fork/upstream/plan.md §0.6 W-108 row): a `Core.Buf(i32)` held
// in a class FIELD, destroyed through the owner's `Destroy` witness at scope
// end — the pin for W-108 ("A `Core.Buf` stored in a field is not freed",
// docs/design/slices.md, 0.1 limits). The lower twin
// (lower/testdata/slice/buf_field.carbon) decides whether `free` is reached
// (R-3); this file pins the check-level shape. Dump ranges only around the
// function bodies, as buf.carbon does (W-121).

// --- synthesized_owner.carbon

library "[[@TEST_NAME]]";

// `Owner` declares no `Destroy` impl, so destroy lookup builds the
// synthesized witness: `CanDestroyClass` answers `NonTrivial` (the field walk
// finds `Buf(i32)`'s declared witness) and upstream's
// `MakeSubobjectDestroyOpBody` (PR 7840) calls `self.b.(Destroy.SelfDestruct)`
// for the field. Predicted at the end of `F`: the `Destroy.SelfDestruct`
// witness call on `o`; in `generated`, `Owner`'s `SubobjectDestroy` body with a
// `class_element_access` of `b` and a `SelfDestruct` call bound to it.
class Owner {
  var b: Core.Buf(i32);
}

//@dump-sem-ir-begin
fn F(n: i64) -> i32 {
  var o: Owner = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}
//@dump-sem-ir-end

// --- declared_owner.carbon

library "[[@TEST_NAME]]";

// `OwnerWithOp` declares its own `Destroy` impl, so destroy lookup selects it
// (D-SL-16) and its `SubobjectDestroy` is the interface's `final` placeholder
// (upstream PR 7773's stated limit: no support for objects with non-trivial
// destruction). Predicted at the end of `G`: the declared-impl destroy
// sequence on `o` (the interface's `SelfDestruct` bound through the impl
// witness); no synthesized `SubobjectDestroy` body for `OwnerWithOp`, so no
// field walk and no `SelfDestruct` call on `b`.
class OwnerWithOp {
  var b: Core.Buf(i32);

  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

//@dump-sem-ir-begin
fn G(n: i64) -> i32 {
  var o: OwnerWithOp = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}
//@dump-sem-ir-end
