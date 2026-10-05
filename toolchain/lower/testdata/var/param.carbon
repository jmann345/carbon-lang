// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/destroy.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/var/param.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/var/param.carbon

// --- with_cleanup.carbon

library "[[@TEST_NAME]]";

class C {
  // TODO: Change to Core.Destructor when possible.
  impl as Core.Destroy {
    fn Op(ref self);
  }

  fn Make() -> Self;
}

fn F(var c: C);

fn G() {
  F(C.Make());
}

// --- struct_literal_cleanup.carbon

library "[[@TEST_NAME]]";

class C {
  // TODO: Change to Core.Destructor when possible.
  impl as Core.Destroy {
    fn Op(ref self);
  }
}

fn F(var c: C);

fn G() {
  F({});
}
