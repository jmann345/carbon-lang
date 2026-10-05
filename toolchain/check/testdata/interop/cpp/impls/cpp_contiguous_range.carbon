// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/impls/cpp_contiguous_range.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/impls/cpp_contiguous_range.carbon

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-9): the synthesized
// `Core.CppContiguousRange` witness (check/cpp/impl_lookup.cpp
// `BuildCppContiguousRangeWitness`), in the cpp_range_for_iterate.carbon
// shape: a test prelude declares the interface so the synthesis fires for it.
// `data()` returns `_Nonnull` pointers here because the primitives prelude has
// no `Core.Optional` for a nullable pointer to map to; the nullable (real
// `std::vector`) shape is stdlib/vector_view.carbon's. `--target` pins
// `unsigned long` to `u64`: on x86_64-linux-gnu `uint64_t` IS `unsigned long`
// (import.cpp `MapBuiltinIntegerType` maps the `uintN_t` type of each width to
// `uN` first; `Core.CppCompat.ULong64` is reached only where `uint64_t` is
// `unsigned long long`, that is Darwin -- primitive_types/long_and_long_long.
// {lp64,darwin,llp64}.carbon pin all three targets). The primitives prelude
// declares `u64` (prelude/parts/uint), so no `CppCompat` name is needed.
//
// Why this golden carried no CHECK lines after the first two hosted fills: the
// check component runs with `--dump-sem-ir-ranges=only`, so a file with no
// `//@dump-sem-ir-begin` range prints no SemIR, and a run with no diagnostics
// prints no stderr -- a clean PASS writes nothing (the precedent's positive
// splits are the same; its CHECK lines are all in `fail_todo_` splits). The
// ranges below make the witness visible in the fill.

// --- cpp_contiguous_range.carbon
package Core library "cpp_contiguous_range";

import library "prelude/parts/bool";

interface CppContiguousRange {
  let DataType: type;
  let SizeType: type;

  // TODO: self must be ref-qualified
  fn Data(self) -> DataType;
  fn Size(self) -> SizeType;
}

interface IsContiguous {
  let Result: bool;
}

final impl forall [T: CppContiguousRange] T as IsContiguous where .Result = true {}
impl forall [T: type] T as IsContiguous where .Result = false {}

fn AssertIsContiguous(unused generic R: IsContiguous where .Result = true) {}
fn AssertIsNotContiguous(unused generic S: IsContiguous where .Result = false) {}

// --- member_data_size.carbon
library "[[@TEST_NAME]]";

import Core library "cpp_contiguous_range";

import Cpp inline '''c++
class V {
 public:
  const int* _Nonnull data() const;
  int* _Nonnull data();
  unsigned long size() const;
};
''';

// Predicted: the witness is built (a `custom_witness` constant naming the two
// member decls); with two `data` overloads the const filter (impl_lookup.cpp
// `LookupCppMethod`) picks `data() const`, so `DataType` is `const i32*`, and
// `SizeType` is `u64` under the `--target` pin.
//@dump-sem-ir-begin
fn Test() {
  Core.AssertIsContiguous(Cpp.V);
  let _: Core.CppContiguousRange where
    .DataType = const i32* and .SizeType = u64 = Cpp.V;
}
//@dump-sem-ir-end

// --- missing_size.carbon
library "[[@TEST_NAME]]";

import Core library "cpp_contiguous_range";

import Cpp inline '''c++
class N {
 public:
  int* _Nonnull data();
};
''';

// Predicted: no `size` member, no witness.
//@dump-sem-ir-begin
fn Test() {
  Core.AssertIsNotContiguous(Cpp.N);
}
//@dump-sem-ir-end

// --- non_const_only.carbon
library "[[@TEST_NAME]]";

import Core library "cpp_contiguous_range";

import Cpp inline '''c++
class M {
 public:
  int* _Nonnull data();
  unsigned long size();
};
''';

// Predicted: single non-const overloads are taken as-is, so `DataType` is
// `i32*`.
//@dump-sem-ir-begin
fn Test() {
  Core.AssertIsContiguous(Cpp.M);
  let _: Core.CppContiguousRange where
    .DataType = i32* and .SizeType = u64 = Cpp.M;
}
//@dump-sem-ir-end
