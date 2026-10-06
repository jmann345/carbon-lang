// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/slice/buf_field.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/slice/buf_field.carbon

// Fork (UA-2, fork/upstream/plan.md §0.6 W-108 row): a `Core.Buf(i32)` held
// in a class FIELD — the arbiter of W-108 ("A `Core.Buf` stored in a field is
// not freed", docs/design/slices.md, 0.1 limits). Whether `call void
// @free(ptr ...)` is reached from the owner's destroy sequence is decided by
// this golden's fill, never asserted (R-3).

// --- synthesized_owner.carbon

library "[[@TEST_NAME]]";

// `Owner` declares no `Destroy` impl. Predicted: at `F`'s exit a call to
// `Owner`'s synthesized `_CSelfDestruct.<hash>:core.Destroy.Core` on
// `%o.var`; its `_CSubobjectDestroy.<hash>:core.Destroy.Core` (upstream's
// field walk, PR 7840) calls `Buf(i32)`'s `_CSelfDestruct.Destroy.Core.<hash>`
// on the field, which calls the declared `_COp.Buf...:Destroy.Core...` whose
// body is `call void @free`. So `free` IS reached in this module — if the fill
// agrees, W-108 is discharged for the aggregate-without-impl shapes.
class Owner {
  var b: Core.Buf(i32);
}

fn F(n: i64) -> i32 {
  var o: Owner = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}

// --- declared_owner.carbon

library "[[@TEST_NAME]]";

// `OwnerWithOp` declares its own `Destroy` impl (D-SL-16 selects it).
// Predicted: at `G`'s exit a call to `_CSelfDestruct.Destroy.Core.<hash>` (the
// interface's `final` `SelfDestruct` specialized to `OwnerWithOp`) on
// `%o.var`, which calls the declared `_COp.OwnerWithOp...:Destroy.Core...`
// (`ret void`) and the interface's `final` placeholder
// `_CSubobjectDestroy.Destroy.Core.<hash>` (`ret void`, upstream PR 7773's
// stated limit). So NO `free` in this module and no `_COp.Buf...` define:
// the block `malloc`ed by `Make` leaks — the W-108 limit that stays for owners
// with a user-declared impl.
class OwnerWithOp {
  var b: Core.Buf(i32);

  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn G(n: i64) -> i32 {
  var o: OwnerWithOp = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}
