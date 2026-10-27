// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/tuple_segment_destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/tuple_segment_destroy.carbon

// --- var.carbon
library "[[@TEST_NAME]]";

fn Sink(n: i32);

class C {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Sink(self.n); }
  }
}

fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  var unused u: (... each T) = t;
}

fn Call(c: C) {
  F((c, 1 as i32, c));
}

// --- let_from_call.carbon
library "[[@TEST_NAME]]";

fn Sink(n: i32);

class C {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Sink(self.n); }
  }
}

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  let unused u: (... each T) = G(t);
}

fn Call(c: C) {
  F((c, 1 as i32));
}

// --- discarded_result.carbon
library "[[@TEST_NAME]]";

fn Sink(n: i32);

class C {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Sink(self.n); }
  }
}

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  G(t);
}

fn Call(c: C) {
  F((1 as i32, c));
}
