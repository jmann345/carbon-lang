// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/if/if_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/if/if_let.carbon

// if-let lowers with zero lowering changes (W-012): the discriminant load
// feeds an `icmp` and a `br` into `if.then`/`if.else`, the payload is read
// in `if.then` under the test, and the var-alternative lane's payload-tuple
// storage is an `alloca` hoisted to the entry block, with only its
// `llvm.lifetime.start` and initializing `store` in the then block.

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  if (let .Some(n: i32) = o) {
    return n;
  } else {
    return 0;
  }
}

fn VarAlternative(o: OptInt) -> i32 {
  if (var .Some(n: i32) = o) {
    n = n + 1;
    return n;
  }
  return 0;
}
