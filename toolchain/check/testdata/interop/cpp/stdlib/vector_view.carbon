// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/vector_view.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/vector_view.carbon

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-9): owning C++ container ->
// `Core.Slice` view through the prelude's blanket
// `impl forall [C: CppContiguous ...] C as ImplicitAs(Slice(C.Element))`
// (core/prelude/types/slice.carbon, beside `Slice`, over the helpers of
// core/prelude/types/cpp/slice.carbon) and the synthesized
// `CppContiguousRange` witness. The header mocks the member shape of
// `std::vector<int>` (D-SL-14; the real one is the conformance program's),
// nullability-complete so that the dump carries no Clang warning. `--target`
// pins `std::size_t` to `unsigned long`, which imports as
// `Core.CppCompat.ULong64`. Positives only.
//
// The projection `C.Element` in the interface argument is the shape of
// impl/lookup/access.carbon (`impl forall [T: Z where .Z1 impls Y] T as
// X(T.Z1.(Y.Y1))`, a concrete query resolving through two nested
// `ImplWitnessAccess`es), so the deducible-parameter spelling of review fold
// rev B B9 is not needed (plan R-9, amended at the round-1 fix).

// --- vector_like.h

namespace std {
  using size_t = __SIZE_TYPE__;
}

class VectorLike {
 public:
  const int* _Nullable data() const;
  int* _Nullable data();
  std::size_t size() const;
};

class NonNullLike {
 public:
  const int* _Nonnull data() const;
  std::size_t size() const;
};

// --- view.carbon

library "[[@TEST_NAME]]";

import Cpp library "vector_like.h";

// Predicted: the blanket `ImplicitAs` witness over the synthesized
// `CppContiguousRange` witness (a `custom_witness` constant naming the `data`
// and `size` function decls); `data() const` is selected by the const filter
// and returns `Optional(const i32*)`, so `CppDataPointer` is the
// `Optional(T*)` impl and `Element` is `const i32`; the size converts through
// `CppSizeToI64` -- `CppCompat.ULong64 as ImplicitAs(u64)` (cpp/int.carbon's
// final impl) then `u64 as As(i64)` -- and the `Data()`/`Size()` temporaries
// destroy through the `CppContiguous` constraint's `Destroy` requirements.
//@dump-sem-ir-begin
fn View(v: Cpp.VectorLike) -> Core.Slice(const i32) {
  return v;
}
//@dump-sem-ir-end

// --- nonnull_data.carbon

library "[[@TEST_NAME]]";

import Cpp library "vector_like.h";

// Predicted: `data()` returns `const i32*` (a `_Nonnull` pointer imports
// without `Optional`), so `CppDataPointer` is the `T*` impl; otherwise as
// `view.carbon`.
//@dump-sem-ir-begin
fn ViewNonNull(v: Cpp.NonNullLike) -> Core.Slice(const i32) {
  return v;
}
//@dump-sem-ir-end
