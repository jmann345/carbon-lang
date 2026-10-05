// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/inline.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/inline.carbon

// ============================================================================
// With definition
// ============================================================================

// --- with_definition.h

inline void inline_with_def() {}

// --- import_with_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "with_definition.h";

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.inline_with_def();
  //@dump-sem-ir-end
}

// ============================================================================
// Without definition
// ============================================================================

// --- without_definition.h

// TODO: Promote this warning to an error by default.
inline void inline_without_def();

// --- todo_fail_import_without_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "without_definition.h";

fn MyF() {
  //@dump-sem-ir-begin
  Cpp.inline_without_def();

  // Don't error on repeated calls.
  Cpp.inline_without_def();
  //@dump-sem-ir-end
}

// ============================================================================
// automatic return type
// ============================================================================

// --- automatic_return_type.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
inline auto WithoutThunk(int) -> auto { return 0; }
inline auto ThunkOnArg(short) -> auto { return 0; }
inline auto ThunkOnReturn(int) -> auto { short x = 0; return x; }
inline auto ThunkOnBoth(short) -> auto { short x = 0; return x; }
''';

fn MyF() {
  //@dump-sem-ir-begin
  let unused r1: i32 = Cpp.WithoutThunk(1);
  let unused r2: i32 = Cpp.ThunkOnArg(1);
  let unused r3: i16 = Cpp.ThunkOnReturn(1);
  let unused r4: i16 = Cpp.ThunkOnBoth(1);
  //@dump-sem-ir-end
}
