// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): `+` returns a `Core.StringBuf` whose
// declared `Destroy` impl runs at the end of the scope; the intermediate
// temporary of a chained `+` in a `var` initializer is destroyed at the end of
// the enclosing block, just before `s` (today's toolchain, ST-1 M-7); and a
// `Core.StringBuf` field of a class without a declared `Destroy` is destroyed
// by that class's synthesized destructor.

fn Concat(a: str, b: str) -> i64 {
  var s: Core.StringBuf = a + b;
  s += "!";
  return s.Size();
}

fn Chain(a: str) -> i64 {
  var s: Core.StringBuf = a + a + a;
  return s.Size();
}

class Holder {
  var text: Core.StringBuf;
}

fn Field(a: str) -> i64 {
  var h: Holder = {.text = a + a};
  return h.text.Size();
}
