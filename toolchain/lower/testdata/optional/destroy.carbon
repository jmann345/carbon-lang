// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/optional/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/optional/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4): destroying a `Core.Optional(T)`
// destroys its value only when it holds one (W-170), `Core.Optional(T*)` has
// no destruction work, `Get()` fails-stop on an empty value (W-173), and
// `Core.Optional(bool)`'s `Get()` loads the `bool` from its storage (W-171).

// --- destroy.carbon

library "[[@TEST_NAME]]";

class Tracked {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn Hold(t: Tracked) {
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
}

fn HoldPointer(p: i32*) {
  var unused o: Core.Optional(i32*) = Core.Optional(i32*).Some(p);
}

// --- get.carbon

library "[[@TEST_NAME]]";

fn GetI32(o: Core.Optional(i32)) -> i32 { return o.Get(); }

fn GetBool(o: Core.Optional(bool)) -> bool { return o.Get(); }
