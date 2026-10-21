// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/index/indirect_index_with.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/index/indirect_index_with.carbon

class Span {
  var ptr: i32*;
}

impl Span as Core.IndirectIndexWith(i32) where .ElementType = i32 {
  fn Ref(self, unused subscript: i32) -> ref i32 {
    return *self.ptr;
  }
}

fn Store(s: Span, v: i32) {
  s.(Core.IndirectIndexWith(i32).Ref)(0) = v;
}

fn Load(s: Span) -> i32 {
  return s.(Core.IndirectIndexWith(i32).Ref)(0);
}

fn LoadViaAt(s: Span) -> i32 {
  return s.(Core.IndexWith(i32).At)(0);
}

fn StoreSubscript(s: Span, i: i32, v: i32) {
  s[i] = v;
}

fn LoadSubscript(s: Span, i: i32) -> i32 {
  return s[i];
}
