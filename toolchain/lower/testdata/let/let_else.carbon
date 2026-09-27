// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/let_else.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/let_else.carbon

// let-else lowers with zero lowering changes (W-012): the discriminant
// compare branches into `let.then`/`let.else`, the else block returns, and
// the success block reads the payload; the var-alternative lane's storage
// is an `alloca` hoisted to the entry block, initialized in `let.then`.

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  let .Some(n: i32) = o else { return -1; }
  return n;
}

fn VarAlternative(o: OptInt) -> i32 {
  var .Some(v: i32) = o else { return 0; }
  v = v + 1;
  return v;
}
