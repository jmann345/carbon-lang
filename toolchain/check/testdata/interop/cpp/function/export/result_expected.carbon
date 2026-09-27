// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/result_expected.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/result_expected.carbon

// Exporting a `Core.Result(T, E)`-returning Carbon function to C++
// (docs/design/error_handling.md, "Exporting fallible Carbon functions:
// `Carbon::expected`"; fork/eh/plan.md §1.B.5-1.B.7, §4.B): the return type
// maps to the class template `Carbon::expected<T', E'>` found BY NAME in the
// TU. Goldens never include the installed `<carbon/expected.h>` (file_test's
// data are the clang headers only), so each split declares a local
// layout-compatible skeleton in its inline C++ — the skeleton needs no
// methods, the golden pins the export mapping, not C++ semantics.
// `fail_no_header` has no skeleton and gets the header-required diagnostic.

// --- result_expected.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F(n: i32) -> Core.Result(i32, i32) {
  if (n < 0) { return Core.Result(i32, i32).Err(n); }
  return Core.Result(i32, i32).Ok(n);
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
template <typename E>
struct expected<void, E> {
  unsigned char disc;
  union {
    E err;
  };
};
struct Exception {
  void* p;
};
}  // namespace Carbon

inline int Use() { return Carbon::F(1).disc; }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.Use(); }
//@dump-sem-ir-end

// --- void_success.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn U(n: i32) -> Core.Result((), i32) {
  if (n < 0) { return Core.Result((), i32).Err(n); }
  return Core.Result((), i32).Ok(());
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
template <typename E>
struct expected<void, E> {
  unsigned char disc;
  union {
    E err;
  };
};
}  // namespace Carbon

// `Core.Result((), i32)` maps to `Carbon::expected<void, int>`.
inline int UseUnit() { return Carbon::U(1).disc; }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.UseUnit(); }
//@dump-sem-ir-end

// --- exception_error.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn X() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(1);
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
struct Exception {
  void* p;
};
}  // namespace Carbon

// `Core.Result(i32, Cpp.Exception)` maps to
// `Carbon::expected<int, Carbon::Exception>`.
inline int UseX() { return Carbon::X().disc; }
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.UseX(); }
//@dump-sem-ir-end

// --- fail_no_header.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F(n: i32) -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(n);
}

inline Cpp '''
inline int Use() { return Carbon::F(1).disc; }
''';
