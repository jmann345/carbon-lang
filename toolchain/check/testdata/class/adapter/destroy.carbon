// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/class/adapter/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/class/adapter/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4): an adapter declares no fields, and
// its object is an object of the adapted type (docs/design/classes.md,
// "Adapters"), so destroying an adapter destroys it as the adapted type (fork
// design F-016): the adapter's `SubobjectDestroy` calls the adapted type's
// `SelfDestruct` when that type has destruction work, and is the no-op builtin
// when it has none.

// --- destructible.carbon

library "[[@TEST_NAME]]";

class P {
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

class AdaptP {
  adapt P;
}

class AdaptAdaptP {
  adapt AdaptP;
}

fn MakeP() -> P;

//@dump-sem-ir-begin
fn F() {
  var unused a: AdaptP = MakeP() as AdaptP;
  var unused b: AdaptAdaptP = MakeP() as AdaptAdaptP;
}
//@dump-sem-ir-end

// --- trivial.carbon

library "[[@TEST_NAME]]";

class AdaptI32 {
  adapt i32;
}

fn MakeAdaptI32() -> AdaptI32;

//@dump-sem-ir-begin
fn G() {
  var unused c: AdaptI32 = MakeAdaptI32();
}
//@dump-sem-ir-end
